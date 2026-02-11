import Foundation

enum OpenClawConnectionState: Equatable {
    case notConfigured
    case checking
    case connected
    case unreachable(String)
}

enum ResolvedConnection: Equatable {
    case lan
    case tunnel

    var label: String {
        switch self {
        case .lan: return "LAN"
        case .tunnel: return "Tunnel"
        }
    }
}

@MainActor
class OpenClawBridge: ObservableObject {
    @Published var lastToolCallStatus: ToolCallStatus = .idle
    @Published var connectionState: OpenClawConnectionState = .notConfigured
    @Published var resolvedConnection: ResolvedConnection?

    private let session: URLSession
    private let pingSession: URLSession
    private let lanPingSession: URLSession
    private var sessionKey: String
    private var conversationHistory: [[String: String]] = []
    private let maxHistoryTurns = 10

    /// Cached resolved endpoint for the session
    private var cachedEndpoint: String?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.session = URLSession(configuration: config)

        let pingConfig = URLSessionConfiguration.default
        pingConfig.timeoutIntervalForRequest = 5
        self.pingSession = URLSession(configuration: pingConfig)

        let lanPingConfig = URLSessionConfiguration.default
        lanPingConfig.timeoutIntervalForRequest = 2
        self.lanPingSession = URLSession(configuration: lanPingConfig)

        self.sessionKey = OpenClawBridge.newSessionKey()
    }

    // MARK: - Endpoint Resolution

    /// Resolve the best endpoint based on connection mode.
    /// Caches the result for the session; call `clearCachedEndpoint()` to force re-discovery.
    func resolveEndpoint() async -> String {
        if let cached = cachedEndpoint {
            return cached
        }

        let mode = OpenGlassConfig.connectionMode
        let lanURL = "\(OpenGlassConfig.lanHost):\(OpenGlassConfig.openClawPort)"
        let tunnelURL = OpenGlassConfig.tunnelHost

        switch mode {
        case .lan:
            cachedEndpoint = lanURL
            resolvedConnection = .lan
            NSLog("[OpenClaw] Using LAN endpoint: %@", lanURL)
            return lanURL

        case .tunnel:
            cachedEndpoint = tunnelURL
            resolvedConnection = .tunnel
            NSLog("[OpenClaw] Using tunnel endpoint: %@", tunnelURL)
            return tunnelURL

        case .auto:
            // Try LAN first with 2s timeout
            if await isReachable(baseURL: lanURL, session: lanPingSession) {
                cachedEndpoint = lanURL
                resolvedConnection = .lan
                NSLog("[OpenClaw] Auto-discovery: LAN reachable, using %@", lanURL)
                return lanURL
            } else {
                cachedEndpoint = tunnelURL
                resolvedConnection = .tunnel
                NSLog("[OpenClaw] Auto-discovery: LAN unreachable, falling back to tunnel %@", tunnelURL)
                return tunnelURL
            }
        }
    }

    /// Get the alternate endpoint (for retry on failure in auto mode).
    private func alternateEndpoint() -> String? {
        guard OpenGlassConfig.connectionMode == .auto else { return nil }
        let lanURL = "\(OpenGlassConfig.lanHost):\(OpenGlassConfig.openClawPort)"
        let tunnelURL = OpenGlassConfig.tunnelHost
        if cachedEndpoint == lanURL {
            return tunnelURL
        } else if cachedEndpoint == tunnelURL {
            return lanURL
        }
        return nil
    }

    func clearCachedEndpoint() {
        cachedEndpoint = nil
        resolvedConnection = nil
    }

    private func isReachable(baseURL: String, session: URLSession) async -> Bool {
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(OpenGlassConfig.openClawGatewayToken)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, (200...499).contains(http.statusCode) {
                return true
            }
        } catch { }
        return false
    }

    func checkConnection() async {
        guard OpenGlassConfig.isOpenClawConfigured else {
            connectionState = .notConfigured
            return
        }
        connectionState = .checking
        let endpoint = await resolveEndpoint()
        guard let url = URL(string: "\(endpoint)/v1/chat/completions") else {
            connectionState = .unreachable("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(OpenGlassConfig.openClawGatewayToken)", forHTTPHeaderField: "Authorization")
        do {
            let (_, response) = try await pingSession.data(for: request)
            if let http = response as? HTTPURLResponse, (200...499).contains(http.statusCode) {
                connectionState = .connected
                NSLog("[OpenClaw] Gateway reachable via %@ (HTTP %d)", resolvedConnection?.label ?? "unknown", http.statusCode)
            } else {
                connectionState = .unreachable("Unexpected response")
            }
        } catch {
            connectionState = .unreachable(error.localizedDescription)
            NSLog("[OpenClaw] Gateway unreachable: %@", error.localizedDescription)
        }
    }

    func resetSession() {
        sessionKey = OpenClawBridge.newSessionKey()
        conversationHistory = []
        NSLog("[OpenClaw] New session: %@", sessionKey)
    }

    private static func newSessionKey() -> String {
        let ts = ISO8601DateFormatter().string(from: Date())
        return "agent:main:glass:\(ts)"
    }

    // MARK: - Agent Chat

    func delegateTask(
        task: String,
        toolName: String = "execute"
    ) async -> ToolResult {
        lastToolCallStatus = .executing(toolName)

        let endpoint = await resolveEndpoint()
        let result = await performRequest(endpoint: endpoint, task: task, toolName: toolName)

        // If failed and in auto mode, retry with alternate endpoint
        if case .failure = result, let alt = alternateEndpoint() {
            NSLog("[OpenClaw] Retrying with alternate endpoint: %@", alt)
            cachedEndpoint = alt
            resolvedConnection = (alt == "\(OpenGlassConfig.lanHost):\(OpenGlassConfig.openClawPort)") ? .lan : .tunnel
            return await performRequest(endpoint: alt, task: task, toolName: toolName)
        }

        return result
    }

    private func performRequest(endpoint: String, task: String, toolName: String) async -> ToolResult {
        guard let url = URL(string: "\(endpoint)/v1/chat/completions") else {
            lastToolCallStatus = .failed(toolName, "Invalid URL")
            return .failure("Invalid gateway URL")
        }

        conversationHistory.append(["role": "user", "content": task])

        if conversationHistory.count > maxHistoryTurns * 2 {
            conversationHistory = Array(conversationHistory.suffix(maxHistoryTurns * 2))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(OpenGlassConfig.openClawGatewayToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionKey, forHTTPHeaderField: "x-openclaw-session-key")

        let body: [String: Any] = [
            "model": "openclaw",
            "messages": conversationHistory,
            "stream": false
        ]

        NSLog("[OpenClaw] Sending %d messages via %@", conversationHistory.count, resolvedConnection?.label ?? "unknown")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await session.data(for: request)
            let httpResponse = response as? HTTPURLResponse

            guard let statusCode = httpResponse?.statusCode, (200...299).contains(statusCode) else {
                let code = httpResponse?.statusCode ?? 0
                let bodyStr = String(data: data, encoding: .utf8) ?? "no body"
                NSLog("[OpenClaw] Chat failed: HTTP %d - %@", code, String(bodyStr.prefix(200)))
                // Remove the user message we just added since it failed
                if conversationHistory.last?["role"] == "user" {
                    conversationHistory.removeLast()
                }
                lastToolCallStatus = .failed(toolName, "HTTP \(code)")
                return .failure("Agent returned HTTP \(code)")
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                conversationHistory.append(["role": "assistant", "content": content])
                NSLog("[OpenClaw] Agent result: %@", String(content.prefix(200)))
                lastToolCallStatus = .completed(toolName)
                return .success(content)
            }

            let raw = String(data: data, encoding: .utf8) ?? "OK"
            conversationHistory.append(["role": "assistant", "content": raw])
            NSLog("[OpenClaw] Agent raw: %@", String(raw.prefix(200)))
            lastToolCallStatus = .completed(toolName)
            return .success(raw)
        } catch {
            NSLog("[OpenClaw] Agent error: %@", error.localizedDescription)
            // Remove the user message we just added since it failed
            if conversationHistory.last?["role"] == "user" {
                conversationHistory.removeLast()
            }
            lastToolCallStatus = .failed(toolName, error.localizedDescription)
            return .failure("Agent error: \(error.localizedDescription)")
        }
    }
}

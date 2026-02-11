import Foundation

enum OpenGlassConfig {
    static let websocketBaseURL = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
    static let model = "models/gemini-2.5-flash-native-audio-preview-12-2025"

    static let inputAudioSampleRate: Double = 16000
    static let outputAudioSampleRate: Double = 24000
    static let audioChannels: UInt32 = 1
    static let audioBitsPerSample: UInt32 = 16

    static let videoFrameInterval: TimeInterval = 1.0
    static let videoJPEGQuality: CGFloat = 0.5

    // Secrets (from Secrets.swift, gitignored)
    static let apiKey = Secrets.geminiAPIKey
    static let openClawHost = Secrets.openClawHost
    static let openClawPort = Secrets.openClawPort
    static let openClawHookToken = Secrets.openClawHookToken
    static let openClawGatewayToken = Secrets.openClawGatewayToken

    static func websocketURL() -> URL? {
        guard isConfigured else { return nil }
        return URL(string: "\(websocketBaseURL)?key=\(apiKey)")
    }

    static var isConfigured: Bool {
        return apiKey != "YOUR_GEMINI_API_KEY" && !apiKey.isEmpty
    }

    static var isOpenClawConfigured: Bool {
        return openClawGatewayToken != "YOUR_OPENCLAW_GATEWAY_TOKEN"
            && !openClawGatewayToken.isEmpty
            && openClawHost != "http://YOUR_MAC_HOSTNAME.local"
    }
}

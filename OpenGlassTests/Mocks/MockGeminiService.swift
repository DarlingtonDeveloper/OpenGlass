import Foundation
import UIKit
@testable import OpenGlass

// MARK: - MockGeminiService
// Mirrors GeminiLiveService interface for testing without real WebSocket connections.

@MainActor
class MockGeminiService: ObservableObject {
    @Published var connectionState: GeminiConnectionState = .disconnected
    @Published var isModelSpeaking: Bool = false

    var onAudioReceived: ((Data) -> Void)?
    var onTurnComplete: (() -> Void)?
    var onInterrupted: (() -> Void)?
    var onDisconnected: ((String?) -> Void)?
    var onInputTranscription: ((String) -> Void)?
    var onOutputTranscription: ((String) -> Void)?
    var onToolCall: ((GeminiToolCall) -> Void)?
    var onToolCallCancellation: ((GeminiToolCallCancellation) -> Void)?

    // Recording
    var connectCallCount = 0
    var disconnectCallCount = 0
    var sentAudioChunks: [Data] = []
    var sentVideoFrames: [UIImage] = []
    var sentToolResponses: [[String: Any]] = []
    var configuredSystemInstruction: String?
    var configuredToolDeclarations: [[String: Any]]?

    // Injection
    var connectResult: Bool = true

    func configure(systemInstruction: String, toolDeclarations: [[String: Any]]) {
        configuredSystemInstruction = systemInstruction
        configuredToolDeclarations = toolDeclarations
    }

    func connect() async -> Bool {
        connectCallCount += 1
        if connectResult {
            connectionState = .ready
        } else {
            connectionState = .error("Mock connection failed")
        }
        return connectResult
    }

    func disconnect() {
        disconnectCallCount += 1
        connectionState = .disconnected
        isModelSpeaking = false
        onToolCall = nil
        onToolCallCancellation = nil
    }

    func sendAudio(data: Data) {
        guard connectionState == .ready else { return }
        sentAudioChunks.append(data)
    }

    func sendVideoFrame(image: UIImage) {
        guard connectionState == .ready else { return }
        sentVideoFrames.append(image)
    }

    func sendToolResponse(_ response: [String: Any]) {
        sentToolResponses.append(response)
    }

    // Test helpers

    func simulateSetupComplete() {
        connectionState = .ready
    }

    func simulateAudioReceived(_ data: Data) {
        isModelSpeaking = true
        onAudioReceived?(data)
    }

    func simulateTurnComplete() {
        isModelSpeaking = false
        onTurnComplete?()
    }

    func simulateInputTranscription(_ text: String) {
        onInputTranscription?(text)
    }

    func simulateOutputTranscription(_ text: String) {
        onOutputTranscription?(text)
    }

    func simulateToolCall(_ json: [String: Any]) {
        if let toolCall = GeminiToolCall(json: json) {
            onToolCall?(toolCall)
        }
    }

    func simulateToolCallCancellation(_ ids: [String]) {
        let json: [String: Any] = ["toolCallCancellation": ["ids": ids]]
        if let cancellation = GeminiToolCallCancellation(json: json) {
            onToolCallCancellation?(cancellation)
        }
    }

    func simulateDisconnected(_ reason: String?) {
        connectionState = .disconnected
        isModelSpeaking = false
        onDisconnected?(reason)
    }
}

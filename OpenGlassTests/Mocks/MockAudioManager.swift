import Foundation
@testable import OpenGlass

// MARK: - MockAudioManager
// Records startCapture/stopCapture/playAudio calls for testing.

class MockAudioManager {
    var onAudioCaptured: ((Data) -> Void)?

    var startCaptureCallCount = 0
    var stopCaptureCallCount = 0
    var playAudioCalls: [Data] = []
    var stopPlaybackCallCount = 0
    var setupAudioSessionCalls: [Bool] = [] // useIPhoneMode values
    var isCapturing = false

    // Injection
    var startCaptureError: Error?
    var setupAudioSessionError: Error?

    func setupAudioSession(useIPhoneMode: Bool = false) throws {
        setupAudioSessionCalls.append(useIPhoneMode)
        if let error = setupAudioSessionError {
            throw error
        }
    }

    func startCapture() throws {
        startCaptureCallCount += 1
        if let error = startCaptureError {
            throw error
        }
        isCapturing = true
    }

    func stopCapture() {
        stopCaptureCallCount += 1
        isCapturing = false
    }

    func playAudio(data: Data) {
        guard isCapturing, !data.isEmpty else { return }
        playAudioCalls.append(data)
    }

    func stopPlayback() {
        stopPlaybackCallCount += 1
    }

    /// Simulate captured audio being sent.
    func simulateAudioCapture(_ data: Data) {
        onAudioCaptured?(data)
    }
}

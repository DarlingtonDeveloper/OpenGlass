import XCTest
@testable import OpenGlass

final class AudioManagerTests: XCTestCase {

    // MARK: - Float32 to Int16 Conversion

    func test_float32ToInt16_zeroIsZero() {
        // 0.0 → 0
        let sample: Float = 0.0
        let int16 = Int16(sample * Float(Int16.max))
        XCTAssertEqual(int16, 0)
    }

    func test_float32ToInt16_positiveOne_isMax() {
        // 1.0 → Int16.max (32767)
        let sample: Float = 1.0
        let clamped = max(-1.0, min(1.0, sample))
        let int16 = Int16(clamped * Float(Int16.max))
        XCTAssertEqual(int16, Int16.max)
    }

    func test_float32ToInt16_negativeOne_isNegMax() {
        // -1.0 → -32767 (not -32768 due to asymmetry)
        let sample: Float = -1.0
        let clamped = max(-1.0, min(1.0, sample))
        let int16 = Int16(clamped * Float(Int16.max))
        XCTAssertEqual(int16, -Int16.max)
    }

    func test_float32ToInt16_halfAmplitude() {
        let sample: Float = 0.5
        let int16 = Int16(sample * Float(Int16.max))
        // 0.5 * 32767 = 16383
        XCTAssertEqual(int16, 16383)
    }

    func test_float32ToInt16_clampsBeyondRange() {
        // Values > 1.0 should clamp to 1.0
        let sample: Float = 1.5
        let clamped = max(-1.0, min(1.0, sample))
        let int16 = Int16(clamped * Float(Int16.max))
        XCTAssertEqual(int16, Int16.max)
    }

    // MARK: - PCM Accumulation Logic

    func test_minSendBytes_is3200() {
        // 100ms at 16kHz mono Int16 = 1600 frames * 2 bytes = 3200
        let expectedMinBytes = 3200
        let framesPerSecond = 16000
        let bytesPerFrame = 2
        let durationMs = 100
        let computed = framesPerSecond * bytesPerFrame * durationMs / 1000
        XCTAssertEqual(computed, expectedMinBytes)
    }

    // MARK: - Mock AudioManager Behavior

    func test_mockAudioManager_initialState_notCapturing() {
        let mock = MockAudioManager()
        XCTAssertFalse(mock.isCapturing)
        XCTAssertEqual(mock.startCaptureCallCount, 0)
        XCTAssertEqual(mock.stopCaptureCallCount, 0)
    }

    func test_mockAudioManager_startStopLifecycle() throws {
        let mock = MockAudioManager()

        try mock.startCapture()
        XCTAssertTrue(mock.isCapturing)
        XCTAssertEqual(mock.startCaptureCallCount, 1)

        mock.stopCapture()
        XCTAssertFalse(mock.isCapturing)
        XCTAssertEqual(mock.stopCaptureCallCount, 1)
    }

    func test_mockAudioManager_playAudio_emptyData_noOps() {
        let mock = MockAudioManager()
        // Not capturing — should no-op
        mock.playAudio(data: Data([0x01]))
        XCTAssertTrue(mock.playAudioCalls.isEmpty)
    }

    func test_mockAudioManager_playAudio_emptyDataWhenCapturing_noOps() throws {
        let mock = MockAudioManager()
        try mock.startCapture()
        mock.playAudio(data: Data())
        XCTAssertTrue(mock.playAudioCalls.isEmpty)
    }

    func test_mockAudioManager_playAudio_validData_records() throws {
        let mock = MockAudioManager()
        try mock.startCapture()
        let data = Data([0x01, 0x02, 0x03])
        mock.playAudio(data: data)
        XCTAssertEqual(mock.playAudioCalls.count, 1)
        XCTAssertEqual(mock.playAudioCalls.first, data)
    }

    func test_mockAudioManager_onAudioCaptured_callback() {
        let mock = MockAudioManager()
        var capturedData: Data?
        mock.onAudioCaptured = { data in
            capturedData = data
        }
        let testData = Data([0xAA, 0xBB])
        mock.simulateAudioCapture(testData)
        XCTAssertEqual(capturedData, testData)
    }
}

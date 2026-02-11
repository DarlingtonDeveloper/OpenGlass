import XCTest
@testable import OpenGlass

@MainActor
final class GeminiSessionViewModelTests: XCTestCase {
    var sut: GeminiSessionViewModel!

    override func setUp() {
        super.setUp()
        sut = GeminiSessionViewModel()
    }

    override func tearDown() {
        sut.stopSession()
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_isInactive() {
        XCTAssertFalse(sut.isGeminiActive)
        XCTAssertEqual(sut.connectionState, .disconnected)
        XCTAssertFalse(sut.isModelSpeaking)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.userTranscript, "")
        XCTAssertEqual(sut.aiTranscript, "")
        XCTAssertEqual(sut.toolCallStatus, .idle)
        XCTAssertTrue(sut.detectedQRCodes.isEmpty)
    }

    // MARK: - Start Session without API key

    func test_startSession_unconfiguredAPIKey_showsError() async {
        // If Secrets has placeholder key, this should set errorMessage
        // Note: This test depends on the build config having a placeholder key.
        // In CI with no real key, OpenGlassConfig.isConfigured will be false.
        guard !OpenGlassConfig.isConfigured else {
            // Real API key present; skip this test
            return
        }

        await sut.startSession()
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("API key") ?? false)
        XCTAssertFalse(sut.isGeminiActive)
    }

    // MARK: - Stop Session

    func test_stopSession_cleansUpAllState() {
        // Manually set some state
        sut.isGeminiActive = true
        sut.isModelSpeaking = true
        sut.userTranscript = "hello"
        sut.aiTranscript = "world"

        sut.stopSession()

        XCTAssertFalse(sut.isGeminiActive)
        XCTAssertEqual(sut.connectionState, .disconnected)
        XCTAssertFalse(sut.isModelSpeaking)
        XCTAssertEqual(sut.userTranscript, "")
        XCTAssertEqual(sut.aiTranscript, "")
        XCTAssertEqual(sut.toolCallStatus, .idle)
        XCTAssertTrue(sut.detectedQRCodes.isEmpty)
    }

    func test_stopSession_canBeCalledWhenAlreadyStopped() {
        sut.stopSession()
        sut.stopSession()
        XCTAssertFalse(sut.isGeminiActive)
    }

    // MARK: - Mode Router

    func test_modeRouter_initialMode_isAssistant() {
        XCTAssertEqual(sut.modeRouter.currentMode.id, "assistant")
    }

    func test_modeRouter_isAccessible() {
        XCTAssertFalse(sut.modeRouter.availableModes.isEmpty)
    }

    // MARK: - Streaming Mode

    func test_streamingMode_defaultIsGlasses() {
        XCTAssertTrue(sut.streamingMode == .glasses)
    }
}

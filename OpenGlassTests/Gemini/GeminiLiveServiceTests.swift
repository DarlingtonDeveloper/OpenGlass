import XCTest
@testable import OpenGlass

@MainActor
final class GeminiLiveServiceTests: XCTestCase {
    var sut: GeminiLiveService!

    override func setUp() {
        super.setUp()
        sut = GeminiLiveService()
    }

    override func tearDown() {
        sut.disconnect()
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialState_isDisconnected() {
        XCTAssertEqual(sut.connectionState, .disconnected)
        XCTAssertFalse(sut.isModelSpeaking)
    }

    // MARK: - Connection Guards

    func test_sendAudio_whenNotReady_doesNotCrash() {
        // Should silently no-op when not connected
        XCTAssertEqual(sut.connectionState, .disconnected)
        let testData = Data([0x00, 0x01, 0x02])
        sut.sendAudio(data: testData)
        // No crash = pass
    }

    func test_sendVideoFrame_whenNotReady_doesNotCrash() {
        XCTAssertEqual(sut.connectionState, .disconnected)
        let image = UIImage()
        sut.sendVideoFrame(image: image)
        // No crash = pass
    }

    // MARK: - Disconnect

    func test_disconnect_cleansUpState() {
        sut.disconnect()
        XCTAssertEqual(sut.connectionState, .disconnected)
        XCTAssertFalse(sut.isModelSpeaking)
        XCTAssertNil(sut.onToolCall)
        XCTAssertNil(sut.onToolCallCancellation)
    }

    func test_disconnect_canBeCalledMultipleTimes() {
        sut.disconnect()
        sut.disconnect()
        XCTAssertEqual(sut.connectionState, .disconnected)
    }

    // MARK: - Configure

    func test_configure_updatesInternalState() {
        // configure is called before connect; we can verify it doesn't crash
        // and that subsequent connect would use these values
        sut.configure(
            systemInstruction: "Test instruction",
            toolDeclarations: [["name": "test_tool"]]
        )
        // No crash = configured successfully
        // Internal state is private, so we verify indirectly through behavior
    }

    // MARK: - Message Parsing (via handleMessage, which is private)
    // These tests verify the parsing logic indirectly through the mock service.
    // For direct testing, handleMessage would need to be internal or testable.
    // See MockGeminiService tests for simulation-based testing.

    // MARK: - Connection State Equatable

    func test_connectionState_equatable() {
        XCTAssertEqual(GeminiConnectionState.disconnected, .disconnected)
        XCTAssertEqual(GeminiConnectionState.connecting, .connecting)
        XCTAssertEqual(GeminiConnectionState.settingUp, .settingUp)
        XCTAssertEqual(GeminiConnectionState.ready, .ready)
        XCTAssertEqual(GeminiConnectionState.error("test"), .error("test"))
        XCTAssertNotEqual(GeminiConnectionState.error("a"), .error("b"))
        XCTAssertNotEqual(GeminiConnectionState.disconnected, .connecting)
    }
}

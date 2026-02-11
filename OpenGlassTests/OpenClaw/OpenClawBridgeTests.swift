import XCTest
@testable import OpenGlass

// NOTE: OpenClawBridge uses URLSession directly. For better testability, consider
// injecting a URLSessionProtocol abstraction so requests can be intercepted in tests.
// Currently, these tests verify the mock and test what we can without network.

@MainActor
final class OpenClawBridgeTests: XCTestCase {

    // MARK: - Mock Bridge Tests

    func test_mockBridge_initialState() {
        let mock = MockOpenClawBridge()
        XCTAssertEqual(mock.lastToolCallStatus, .idle)
        XCTAssertEqual(mock.connectionState, .notConfigured)
        XCTAssertTrue(mock.delegatedTasks.isEmpty)
    }

    func test_mockBridge_checkConnection() async {
        let mock = MockOpenClawBridge()
        mock.checkConnectionResult = .connected
        await mock.checkConnection()
        XCTAssertEqual(mock.connectionState, .connected)
        XCTAssertEqual(mock.checkConnectionCallCount, 1)
    }

    func test_mockBridge_checkConnection_unreachable() async {
        let mock = MockOpenClawBridge()
        mock.checkConnectionResult = .unreachable("timeout")
        await mock.checkConnection()
        XCTAssertEqual(mock.connectionState, .unreachable("timeout"))
    }

    func test_mockBridge_delegateTask_recordsCall() async {
        let mock = MockOpenClawBridge()
        mock.delegateTaskResult = .success("test result")

        let result = await mock.delegateTask(task: "search the web", toolName: "execute")

        XCTAssertEqual(mock.delegatedTasks.count, 1)
        XCTAssertEqual(mock.delegatedTasks.first?.task, "search the web")
        XCTAssertEqual(mock.delegatedTasks.first?.toolName, "execute")

        if case .success(let value) = result {
            XCTAssertEqual(value, "test result")
        } else {
            XCTFail("Expected success")
        }
    }

    func test_mockBridge_delegateTask_failure() async {
        let mock = MockOpenClawBridge()
        mock.delegateTaskResult = .failure("Network error")

        let result = await mock.delegateTask(task: "do something", toolName: "execute")

        if case .failure(let msg) = result {
            XCTAssertEqual(msg, "Network error")
        } else {
            XCTFail("Expected failure")
        }
        XCTAssertEqual(mock.lastToolCallStatus, .failed("execute", "Network error"))
    }

    func test_mockBridge_resetSession() {
        let mock = MockOpenClawBridge()
        mock.resetSession()
        XCTAssertEqual(mock.resetSessionCallCount, 1)
    }

    // MARK: - Real Bridge State Tests (no network)

    func test_realBridge_initialState() {
        let bridge = OpenClawBridge()
        XCTAssertEqual(bridge.lastToolCallStatus, .idle)
        // connectionState depends on config
    }

    func test_realBridge_resetSession_clearsState() {
        let bridge = OpenClawBridge()
        bridge.resetSession()
        // Should not crash; internal history is cleared
        XCTAssertEqual(bridge.lastToolCallStatus, .idle)
    }

    // MARK: - OpenClawConnectionState Equatable

    func test_connectionState_equatable() {
        XCTAssertEqual(OpenClawConnectionState.notConfigured, .notConfigured)
        XCTAssertEqual(OpenClawConnectionState.checking, .checking)
        XCTAssertEqual(OpenClawConnectionState.connected, .connected)
        XCTAssertEqual(OpenClawConnectionState.unreachable("a"), .unreachable("a"))
        XCTAssertNotEqual(OpenClawConnectionState.unreachable("a"), .unreachable("b"))
        XCTAssertNotEqual(OpenClawConnectionState.connected, .checking)
    }
}

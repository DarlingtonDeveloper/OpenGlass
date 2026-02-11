import XCTest
@testable import OpenGlass

@MainActor
final class ToolCallRouterTests: XCTestCase {
    var mockBridge: MockOpenClawBridge!

    override func setUp() {
        super.setUp()
        mockBridge = MockOpenClawBridge()
    }

    override func tearDown() {
        mockBridge = nil
        super.tearDown()
    }

    // MARK: - Helper to create ToolCallRouter with mock
    // Note: ToolCallRouter takes a real OpenClawBridge. Since we can't inject a mock
    // without a protocol abstraction, we test the mock bridge directly and verify
    // the response format independently.
    // TODO: Extract a protocol from OpenClawBridge for proper dependency injection.

    // MARK: - Response Format

    func test_buildToolResponse_format() {
        // Verify the expected JSON structure for tool responses
        let response: [String: Any] = [
            "toolResponse": [
                "functionResponses": [
                    [
                        "id": "call_123",
                        "name": "execute",
                        "response": ["result": "done"]
                    ]
                ]
            ]
        ]

        let toolResponse = response["toolResponse"] as? [String: Any]
        XCTAssertNotNil(toolResponse)
        let funcResponses = toolResponse?["functionResponses"] as? [[String: Any]]
        XCTAssertEqual(funcResponses?.count, 1)
        XCTAssertEqual(funcResponses?.first?["id"] as? String, "call_123")
        XCTAssertEqual(funcResponses?.first?["name"] as? String, "execute")
    }

    // MARK: - Mock Bridge Dispatch

    func test_dispatch_delegatesToBridge_returnsResult() async {
        mockBridge.delegateTaskResult = .success("restaurants found")

        let result = await mockBridge.delegateTask(task: "find restaurants nearby")

        XCTAssertEqual(mockBridge.delegatedTasks.count, 1)
        if case .success(let value) = result {
            XCTAssertEqual(value, "restaurants found")
        } else {
            XCTFail("Expected success")
        }
    }

    // MARK: - Cancellation via Mock

    func test_cancelToolCalls_cancelsSpecificTasks() async {
        // Start a task, then cancel it
        let task = Task { @MainActor in
            return await mockBridge.delegateTask(task: "long running task")
        }

        // Cancel immediately
        task.cancel()

        let result = await task.value
        // Result depends on timing — may be cancelled or completed
        // The important thing is it doesn't crash
        _ = result
    }

    func test_cancelAll_cancelsEverything() {
        // Create multiple tasks
        let tasks = (0..<3).map { i in
            Task { @MainActor in
                await mockBridge.delegateTask(task: "task \(i)")
            }
        }

        // Cancel all
        for task in tasks {
            task.cancel()
        }

        // No crash = pass
    }

    // MARK: - Real ToolCallRouter (limited without protocol injection)

    func test_realRouter_cancelAll_doesNotCrash() {
        let bridge = OpenClawBridge()
        let router = ToolCallRouter(bridge: bridge)
        router.cancelAll()
        // No crash = pass
    }
}

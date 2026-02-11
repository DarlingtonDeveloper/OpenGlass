import XCTest
@testable import OpenGlass

@MainActor
final class ToolCallIntegrationTests: XCTestCase {

    // MARK: - Full Tool Call Flow

    func test_fullToolCallFlow_parseDispatchRespond() async {
        // 1. Parse tool call JSON (as received from Gemini)
        let json: [String: Any] = [
            "toolCall": [
                "functionCalls": [
                    [
                        "id": "call_abc",
                        "name": "execute",
                        "args": ["task": "add milk to shopping list"]
                    ]
                ]
            ]
        ]
        let toolCall = GeminiToolCall(json: json)
        XCTAssertNotNil(toolCall)

        let call = toolCall!.functionCalls.first!
        XCTAssertEqual(call.id, "call_abc")
        XCTAssertEqual(call.name, "execute")

        // 2. Dispatch to mock bridge
        let mockBridge = MockOpenClawBridge()
        mockBridge.delegateTaskResult = .success("Added milk to your shopping list")

        let taskDesc = call.args["task"] as? String ?? ""
        let result = await mockBridge.delegateTask(task: taskDesc, toolName: call.name)

        XCTAssertEqual(mockBridge.delegatedTasks.count, 1)
        XCTAssertEqual(mockBridge.delegatedTasks.first?.task, "add milk to shopping list")

        // 3. Build response
        let responseValue: [String: Any]
        switch result {
        case .success(let val):
            responseValue = ["result": val]
        case .failure(let err):
            responseValue = ["error": err]
        }

        let response: [String: Any] = [
            "toolResponse": [
                "functionResponses": [
                    [
                        "id": call.id,
                        "name": call.name,
                        "response": responseValue
                    ]
                ]
            ]
        ]

        // 4. Verify response structure
        let toolResponse = response["toolResponse"] as? [String: Any]
        let funcResponses = toolResponse?["functionResponses"] as? [[String: Any]]
        XCTAssertEqual(funcResponses?.count, 1)
        XCTAssertEqual(funcResponses?.first?["id"] as? String, "call_abc")

        let respContent = funcResponses?.first?["response"] as? [String: Any]
        XCTAssertEqual(respContent?["result"] as? String, "Added milk to your shopping list")
    }

    // MARK: - Tool Call Cancellation Flow

    func test_toolCallCancellation_parsesAndCancels() {
        // Parse cancellation
        let json: [String: Any] = [
            "toolCallCancellation": [
                "ids": ["call_1", "call_2"]
            ]
        ]
        let cancellation = GeminiToolCallCancellation(json: json)
        XCTAssertNotNil(cancellation)
        XCTAssertEqual(cancellation?.ids.count, 2)

        // Create tasks and cancel them
        var cancelledIds: [String] = []
        let tasks: [String: Task<Void, Never>] = [
            "call_1": Task { try? await Task.sleep(nanoseconds: 10_000_000_000) },
            "call_2": Task { try? await Task.sleep(nanoseconds: 10_000_000_000) }
        ]

        for id in cancellation!.ids {
            if let task = tasks[id] {
                task.cancel()
                cancelledIds.append(id)
            }
        }

        XCTAssertEqual(cancelledIds, ["call_1", "call_2"])
    }

    // MARK: - Multiple Concurrent Tool Calls

    func test_multipleConcurrentToolCalls() async {
        let mockBridge = MockOpenClawBridge()
        mockBridge.delegateTaskResult = .success("Done")

        // Fire multiple concurrent calls
        async let r1 = mockBridge.delegateTask(task: "task 1", toolName: "execute")
        async let r2 = mockBridge.delegateTask(task: "task 2", toolName: "execute")
        async let r3 = mockBridge.delegateTask(task: "task 3", toolName: "execute")

        let results = await [r1, r2, r3]

        XCTAssertEqual(mockBridge.delegatedTasks.count, 3)
        for result in results {
            if case .success(let val) = result {
                XCTAssertEqual(val, "Done")
            } else {
                XCTFail("Expected success")
            }
        }
    }

    // MARK: - Tool Call with Failure

    func test_toolCallFlow_bridgeReturnsFailure() async {
        let mockBridge = MockOpenClawBridge()
        mockBridge.delegateTaskResult = .failure("Gateway unreachable")

        let result = await mockBridge.delegateTask(task: "search something")

        if case .failure(let msg) = result {
            XCTAssertEqual(msg, "Gateway unreachable")
        } else {
            XCTFail("Expected failure")
        }
        XCTAssertEqual(mockBridge.lastToolCallStatus, .failed("execute", "Gateway unreachable"))
    }

    // MARK: - End-to-End: Mock Gemini → Tool Call → Mock Bridge

    func test_endToEnd_geminiToolCallToMockBridge() async {
        let mockGemini = MockGeminiService()
        let mockBridge = MockOpenClawBridge()
        mockBridge.delegateTaskResult = .success("Message sent to Alice")

        var sentResponses: [[String: Any]] = []

        // Wire up: Gemini tool call → dispatch to bridge → send response back
        mockGemini.onToolCall = { toolCall in
            Task { @MainActor in
                for call in toolCall.functionCalls {
                    let taskDesc = call.args["task"] as? String ?? ""
                    let result = await mockBridge.delegateTask(task: taskDesc, toolName: call.name)
                    let response: [String: Any] = [
                        "toolResponse": [
                            "functionResponses": [[
                                "id": call.id,
                                "name": call.name,
                                "response": result.responseValue
                            ]]
                        ]
                    ]
                    mockGemini.sendToolResponse(response)
                    sentResponses.append(response)
                }
            }
        }

        // Simulate incoming tool call
        let toolCallJSON: [String: Any] = [
            "toolCall": [
                "functionCalls": [[
                    "id": "call_xyz",
                    "name": "execute",
                    "args": ["task": "send a message to Alice saying hi"]
                ]]
            ]
        ]
        mockGemini.simulateToolCall(toolCallJSON)

        // Wait for async processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        XCTAssertEqual(mockBridge.delegatedTasks.count, 1)
        XCTAssertEqual(mockBridge.delegatedTasks.first?.task, "send a message to Alice saying hi")
        XCTAssertEqual(mockGemini.sentToolResponses.count, 1)
    }
}

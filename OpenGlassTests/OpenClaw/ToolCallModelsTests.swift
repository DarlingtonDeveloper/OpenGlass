import XCTest
@testable import OpenGlass

final class ToolCallModelsTests: XCTestCase {

    // MARK: - GeminiToolCall Parsing

    func test_geminiToolCall_validJSON_parses() {
        let json: [String: Any] = [
            "toolCall": [
                "functionCalls": [
                    [
                        "id": "call_123",
                        "name": "execute",
                        "args": ["task": "search for restaurants"]
                    ]
                ]
            ]
        ]
        let toolCall = GeminiToolCall(json: json)
        XCTAssertNotNil(toolCall)
        XCTAssertEqual(toolCall?.functionCalls.count, 1)
        XCTAssertEqual(toolCall?.functionCalls.first?.id, "call_123")
        XCTAssertEqual(toolCall?.functionCalls.first?.name, "execute")
        XCTAssertEqual(toolCall?.functionCalls.first?.args["task"] as? String, "search for restaurants")
    }

    func test_geminiToolCall_multipleFunctions_parsesAll() {
        let json: [String: Any] = [
            "toolCall": [
                "functionCalls": [
                    ["id": "c1", "name": "execute", "args": ["task": "first"]],
                    ["id": "c2", "name": "execute", "args": ["task": "second"]]
                ]
            ]
        ]
        let toolCall = GeminiToolCall(json: json)
        XCTAssertEqual(toolCall?.functionCalls.count, 2)
    }

    func test_geminiToolCall_noArgs_defaultsToEmptyDict() {
        let json: [String: Any] = [
            "toolCall": [
                "functionCalls": [
                    ["id": "c1", "name": "execute"]
                ]
            ]
        ]
        let toolCall = GeminiToolCall(json: json)
        XCTAssertNotNil(toolCall)
        XCTAssertTrue(toolCall?.functionCalls.first?.args.isEmpty ?? false)
    }

    func test_geminiToolCall_invalidJSON_returnsNil() {
        let json: [String: Any] = ["serverContent": ["turnComplete": true]]
        XCTAssertNil(GeminiToolCall(json: json))
    }

    func test_geminiToolCall_missingFunctionCalls_returnsNil() {
        let json: [String: Any] = ["toolCall": [:] as [String: Any]]
        XCTAssertNil(GeminiToolCall(json: json))
    }

    func test_geminiToolCall_emptyJSON_returnsNil() {
        XCTAssertNil(GeminiToolCall(json: [:]))
    }

    // MARK: - GeminiToolCallCancellation

    func test_cancellation_validJSON_parses() {
        let json: [String: Any] = [
            "toolCallCancellation": [
                "ids": ["call_1", "call_2"]
            ]
        ]
        let cancellation = GeminiToolCallCancellation(json: json)
        XCTAssertNotNil(cancellation)
        XCTAssertEqual(cancellation?.ids, ["call_1", "call_2"])
    }

    func test_cancellation_invalidJSON_returnsNil() {
        XCTAssertNil(GeminiToolCallCancellation(json: ["foo": "bar"]))
    }

    func test_cancellation_missingIds_returnsNil() {
        let json: [String: Any] = ["toolCallCancellation": [:] as [String: Any]]
        XCTAssertNil(GeminiToolCallCancellation(json: json))
    }

    // MARK: - ToolResult

    func test_toolResult_success_responseValue() {
        let result = ToolResult.success("Done!")
        let value = result.responseValue
        XCTAssertEqual(value["result"] as? String, "Done!")
        XCTAssertNil(value["error"])
    }

    func test_toolResult_failure_responseValue() {
        let result = ToolResult.failure("Something broke")
        let value = result.responseValue
        XCTAssertEqual(value["error"] as? String, "Something broke")
        XCTAssertNil(value["result"])
    }

    // MARK: - ToolCallStatus

    func test_toolCallStatus_idle_notActive() {
        XCTAssertFalse(ToolCallStatus.idle.isActive)
    }

    func test_toolCallStatus_executing_isActive() {
        XCTAssertTrue(ToolCallStatus.executing("test").isActive)
    }

    func test_toolCallStatus_completed_notActive() {
        XCTAssertFalse(ToolCallStatus.completed("test").isActive)
    }

    func test_toolCallStatus_displayText() {
        XCTAssertEqual(ToolCallStatus.idle.displayText, "")
        XCTAssertTrue(ToolCallStatus.executing("foo").displayText.contains("foo"))
        XCTAssertTrue(ToolCallStatus.completed("bar").displayText.contains("bar"))
        XCTAssertTrue(ToolCallStatus.failed("baz", "err").displayText.contains("baz"))
        XCTAssertTrue(ToolCallStatus.cancelled("qux").displayText.contains("qux"))
    }

    // MARK: - ToolDeclarations

    func test_allDeclarations_returnsExecuteTool() {
        let decls = ToolDeclarations.allDeclarations()
        XCTAssertEqual(decls.count, 1)
        XCTAssertEqual(decls.first?["name"] as? String, "execute")
    }

    func test_executeDeclaration_hasRequiredFields() {
        let exec = ToolDeclarations.execute
        XCTAssertEqual(exec["name"] as? String, "execute")
        XCTAssertNotNil(exec["description"])
        XCTAssertNotNil(exec["parameters"])
        XCTAssertEqual(exec["behavior"] as? String, "BLOCKING")
    }

    func test_executeDeclaration_parametersStructure() {
        let params = ToolDeclarations.execute["parameters"] as? [String: Any]
        XCTAssertEqual(params?["type"] as? String, "object")
        let properties = params?["properties"] as? [String: Any]
        XCTAssertNotNil(properties?["task"])
        let required = params?["required"] as? [String]
        XCTAssertTrue(required?.contains("task") ?? false)
    }
}

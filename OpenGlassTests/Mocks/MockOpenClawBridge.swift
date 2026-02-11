import Foundation
@testable import OpenGlass

// MARK: - MockOpenClawBridge
// Records delegateTask calls and returns configurable results.
// Note: Since OpenClawBridge doesn't conform to a protocol, this mock duplicates the interface.
// For better testability, consider extracting a protocol from OpenClawBridge.

@MainActor
class MockOpenClawBridge {
    var lastToolCallStatus: ToolCallStatus = .idle
    var connectionState: OpenClawConnectionState = .notConfigured

    // Recording
    var delegatedTasks: [(task: String, toolName: String)] = []
    var checkConnectionCallCount = 0
    var resetSessionCallCount = 0

    // Injection
    var delegateTaskResult: ToolResult = .success("Mock result")
    var checkConnectionResult: OpenClawConnectionState = .connected

    func checkConnection() async {
        checkConnectionCallCount += 1
        connectionState = checkConnectionResult
    }

    func resetSession() {
        resetSessionCallCount += 1
    }

    func delegateTask(task: String, toolName: String = "execute") async -> ToolResult {
        delegatedTasks.append((task: task, toolName: toolName))
        lastToolCallStatus = .executing(toolName)

        // Simulate brief processing
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

        if Task.isCancelled {
            lastToolCallStatus = .cancelled(toolName)
            return .failure("Cancelled")
        }

        let result = delegateTaskResult
        switch result {
        case .success:
            lastToolCallStatus = .completed(toolName)
        case .failure(let msg):
            lastToolCallStatus = .failed(toolName, msg)
        }
        return result
    }
}

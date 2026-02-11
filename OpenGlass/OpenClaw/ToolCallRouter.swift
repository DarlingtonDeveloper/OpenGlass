// OpenGlass - ToolCallRouter.swift

import Foundation

/// Routes Gemini tool calls to the appropriate handler (OpenClaw or local).
/// TODO: Parse tool call from Gemini response (function name + arguments)
/// TODO: Route to OpenClawBridge for remote skills
/// TODO: Handle local tool calls (e.g., mode switching, config changes)
/// TODO: Return tool results back to Gemini for conversation integration
class ToolCallRouter {
    // TODO: route(toolCall:) async throws -> ToolCallResult
    // TODO: Register local tool handlers
}

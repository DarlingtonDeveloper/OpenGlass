// OpenGlass - ToolCallModels.swift

import Foundation

/// Data models for Gemini tool calls and OpenClaw skill invocations.

/// Represents a tool call received from Gemini.
/// TODO: Parse from Gemini WebSocket message
struct ToolCall: Codable {
    let id: String
    let functionName: String
    let arguments: [String: String]
}

/// Represents the result of a tool call execution.
/// TODO: Serialize back to Gemini as tool response
struct ToolCallResult: Codable {
    let id: String
    let result: String
    let isError: Bool
}

/// Represents an OpenClaw skill invocation request.
/// TODO: Map from ToolCall to OpenClaw API format
struct OpenClawRequest: Codable {
    let skill: String
    let parameters: [String: String]
}

/// Represents an OpenClaw skill response.
/// TODO: Parse from OpenClaw Gateway HTTP response
struct OpenClawResponse: Codable {
    let success: Bool
    let result: String?
    let error: String?
}

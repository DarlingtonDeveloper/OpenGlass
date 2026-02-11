// OpenGlass - AssistantMode.swift

import Foundation

/// Default general-purpose assistant mode.
/// TODO: Scene description ("What am I looking at?")
/// TODO: OCR and text reading ("Read that sign")
/// TODO: Context memory ("Remember this")
/// TODO: Full tool access for OpenClaw skills
struct AssistantMode: OpenGlassMode {
    let id = "assistant"
    let displayName = "Assistant"
    let systemInstruction = "You are a helpful AI assistant with access to vision and tools. Describe what you see when asked, read text, and help with tasks."
    let enabledTools = ["*"] // All tools

    func activate() { /* TODO */ }
    func deactivate() { /* TODO */ }
}

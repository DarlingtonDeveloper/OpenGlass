// OpenGlass - ModeProtocol.swift

import Foundation

/// Defines the interface that all OpenGlass modes must implement.
/// TODO: Each mode provides a system instruction for Gemini
/// TODO: Each mode declares which tools it needs
/// TODO: Each mode can provide a custom SwiftUI overlay view
/// TODO: Modes handle activation/deactivation lifecycle
protocol OpenGlassMode {
    var id: String { get }
    var displayName: String { get }
    var systemInstruction: String { get }
    var enabledTools: [String] { get }

    func activate()
    func deactivate()
}

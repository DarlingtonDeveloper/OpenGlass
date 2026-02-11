// OpenGlass - GeminiSessionViewModel.swift

import Foundation
import SwiftUI

/// ViewModel binding Gemini session state to SwiftUI views.
/// TODO: Publish connection state (disconnected, connecting, connected, error)
/// TODO: Publish transcript (array of messages with role + text)
/// TODO: Publish current audio level (for visualisation)
/// TODO: Handle mode changes (update system instruction)
/// TODO: Expose connect/disconnect actions
@Observable
class GeminiSessionViewModel {
    var isConnected: Bool = false
    var transcript: [String] = []
    // TODO: Integrate with GeminiLiveService
}

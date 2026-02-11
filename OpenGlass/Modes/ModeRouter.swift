// OpenGlass - ModeRouter.swift

import Foundation
import SwiftUI

/// State machine managing the active mode and transitions.
/// TODO: Register available modes
/// TODO: Switch modes cleanly (deactivate old, activate new)
/// TODO: Update Gemini session with new system instruction on switch
/// TODO: Support voice-triggered mode switching
/// TODO: Persist last active mode across app launches
@Observable
class ModeRouter {
    var activeMode: (any OpenGlassMode)?
    var availableModes: [any OpenGlassMode] = []

    // TODO: switchMode(_ id: String)
    // TODO: registerMode(_ mode: OpenGlassMode)
}

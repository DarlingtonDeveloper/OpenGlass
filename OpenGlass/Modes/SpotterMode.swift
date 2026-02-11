// OpenGlass - SpotterMode.swift

import Foundation

/// Visual spotter mode — watches for configured objects/events.
/// TODO: Accept a list of things to watch for (objects, people, text, events)
/// TODO: Run continuous frame analysis with focused prompt
/// TODO: Alert user immediately when a target is spotted
/// TODO: Configurable alert style (audio, haptic, visual)
struct SpotterMode: OpenGlassMode {
    let id = "spotter"
    let displayName = "Spotter"
    let systemInstruction = "You are watching for specific items. Analyse each frame carefully and alert immediately if you see any of the configured targets."
    let enabledTools: [String] = []

    func activate() { /* TODO: Load spotter targets from config */ }
    func deactivate() { /* TODO */ }
}

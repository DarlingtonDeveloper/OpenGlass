// OpenGlass - SettingsView.swift

import SwiftUI

/// App settings view for configuration.
/// TODO: Gemini API key input (secure field)
/// TODO: OpenClaw gateway URL configuration
/// TODO: Frame rate slider (0.5 - 5 fps)
/// TODO: JPEG quality slider
/// TODO: Audio input/output device selection
/// TODO: Custom mode editor
/// TODO: About section with version info
struct SettingsView: View {
    var body: some View {
        Form {
            Section("Gemini") {
                // TODO: API key field
            }
            Section("OpenClaw") {
                // TODO: Gateway URL field
            }
            Section("Vision") {
                // TODO: Frame rate, JPEG quality
            }
        }
        .navigationTitle("Settings")
    }
}

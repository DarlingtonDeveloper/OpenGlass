// OpenGlass - ContentView.swift

import SwiftUI

/// Root view that hosts the mode-specific UI and navigation.
/// TODO: Display current mode's overlay view
/// TODO: Show transcript view as an overlay
/// TODO: Add mode picker access (swipe or button)
/// TODO: Show connection status indicator (Gemini + OpenClaw + Glasses)
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("OpenGlass 🕶️")
                    .font(.largeTitle)
                Text("Coming soon")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}

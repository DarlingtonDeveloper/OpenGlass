// OpenGlass - ModePickerView.swift

import SwiftUI

/// Mode selection UI — allows switching between available modes.
/// TODO: Display available modes in a grid or list
/// TODO: Highlight currently active mode
/// TODO: Trigger mode switch via ModeRouter on selection
/// TODO: Show mode description and icon
struct ModePickerView: View {
    var body: some View {
        VStack {
            Text("Select Mode")
                .font(.headline)
            // TODO: Mode grid/list
        }
        .navigationTitle("Modes")
    }
}

// OpenGlass - TranscriptView.swift

import SwiftUI

/// Displays the live conversation transcript as an overlay.
/// TODO: Show scrolling list of messages (user + assistant)
/// TODO: Auto-scroll to latest message
/// TODO: Distinguish user speech from assistant responses
/// TODO: Show tool call activity indicators
/// TODO: Translucent overlay style for use over camera preview
struct TranscriptView: View {
    var body: some View {
        ScrollView {
            // TODO: Message list
            Text("Transcript will appear here")
                .foregroundStyle(.secondary)
        }
    }
}

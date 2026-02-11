import SwiftUI

struct TranscriptView: View {
    let userTranscript: String
    let aiTranscript: String
    let toolCallStatus: ToolCallStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !userTranscript.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(userTranscript)
                        .font(.body)
                        .foregroundColor(.white)
                }
                .transition(.opacity)
            }

            if !aiTranscript.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text(aiTranscript)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                .transition(.opacity)
            }

            if toolCallStatus.isActive {
                HStack(spacing: 6) {
                    ProgressView()
                        .tint(.orange)
                        .scaleEffect(0.7)
                    Text(toolCallStatus.displayText)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: userTranscript)
        .animation(.easeInOut(duration: 0.2), value: aiTranscript)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .opacity(userTranscript.isEmpty && aiTranscript.isEmpty && !toolCallStatus.isActive ? 0 : 1)
    }
}

#Preview {
    TranscriptView(
        userTranscript: "What's the weather like?",
        aiTranscript: "Let me check that for you.",
        toolCallStatus: .executing("execute")
    )
    .padding()
    .background(Color.black)
}

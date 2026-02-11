import SwiftUI

/// Stub UI for Meta Ray-Ban glasses pairing via DAT SDK.
struct GlassesConnectionView: View {
    @State private var isPairing = false
    @State private var statusMessage = "No glasses connected"

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "eyeglasses")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Meta Ray-Ban Smart Glasses")
                .font(.title2.bold())

            Text(statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if isPairing {
                ProgressView("Searching for glasses...")
            } else {
                Button {
                    startPairing()
                } label: {
                    Text("Pair Glasses")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                }
            }

            Text("Requires Meta DAT SDK integration.\nThis feature is not yet available.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .navigationTitle("Glasses")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func startPairing() {
        isPairing = true
        // TODO: Integrate DAT SDK pairing flow
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            isPairing = false
            statusMessage = "DAT SDK not yet integrated. Use iPhone camera mode for now."
        }
    }
}

#Preview {
    NavigationStack {
        GlassesConnectionView()
    }
}

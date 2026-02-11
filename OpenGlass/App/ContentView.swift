import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: GeminiSessionViewModel
    @EnvironmentObject var modeRouter: ModeRouter
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: mode indicator + settings
                HStack {
                    // Mode indicator
                    HStack(spacing: 6) {
                        Image(systemName: modeRouter.currentMode.icon)
                            .font(.title3)
                        Text(modeRouter.currentMode.name)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                    Spacer()

                    // Connection status
                    connectionIndicator

                    // Settings
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Transcript overlay
                TranscriptView(
                    userTranscript: session.userTranscript,
                    aiTranscript: session.aiTranscript,
                    toolCallStatus: session.toolCallStatus
                )
                .padding(.horizontal)

                // Mode picker
                ModePickerView()
                    .padding(.vertical, 8)

                // Connect / Disconnect button
                Button {
                    Task {
                        if session.isGeminiActive {
                            session.stopSession()
                        } else {
                            await session.startSession()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: session.isGeminiActive ? "stop.circle.fill" : "play.circle.fill")
                        Text(session.isGeminiActive ? "Disconnect" : "Connect")
                    }
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(session.isGeminiActive ? Color.red : Color.blue, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }

            // Error banner
            if let error = session.errorMessage {
                VStack {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                        .onTapGesture {
                            session.errorMessage = nil
                        }
                    Spacer()
                }
                .padding(.top, 60)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    @ViewBuilder
    private var connectionIndicator: some View {
        let (color, label) = connectionInfo
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.trailing, 8)
    }

    private var connectionInfo: (Color, String) {
        switch session.connectionState {
        case .disconnected: return (.gray, "Off")
        case .connecting, .settingUp: return (.yellow, "Connecting")
        case .ready: return (.green, "Live")
        case .error: return (.red, "Error")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GeminiSessionViewModel())
        .environmentObject(ModeRouter())
}

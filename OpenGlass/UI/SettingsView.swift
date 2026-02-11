import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: GeminiSessionViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("streamingMode") private var streamingModeRaw: String = "iPhone"
    @AppStorage("connectionMode") private var connectionModeRaw: String = ConnectionMode.auto.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("Connection") {
                    HStack {
                        Text("Gemini API")
                        Spacer()
                        statusBadge(configured: OpenGlassConfig.isConfigured)
                    }
                    HStack {
                        Text("OpenClaw Gateway")
                        Spacer()
                        statusBadge(configured: OpenGlassConfig.isOpenClawConfigured)
                    }

                    if case .connected = session.openClawConnectionState {
                        HStack {
                            Text("Gateway Status")
                            Spacer()
                            Text("Connected")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }

                Section("OpenClaw Connection Mode") {
                    Picker("Mode", selection: $connectionModeRaw) {
                        ForEach(ConnectionMode.allCases, id: \.rawValue) { mode in
                            Text(mode.rawValue).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.automatic)
                    .onChange(of: connectionModeRaw) { _, newValue in
                        if let mode = ConnectionMode(rawValue: newValue) {
                            OpenGlassConfig.connectionMode = mode
                        }
                    }

                    HStack {
                        Text("LAN Host")
                        Spacer()
                        Text(OpenGlassConfig.lanHost)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }

                    HStack {
                        Text("Tunnel Host")
                        Spacer()
                        Text(OpenGlassConfig.tunnelHost)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }

                    if let resolved = session.openClawBridge.resolvedConnection {
                        HStack {
                            Text("Connected via")
                            Spacer()
                            Text(resolved.label)
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                }

                Section("Camera Source") {
                    Picker("Mode", selection: $streamingModeRaw) {
                        Text("iPhone Camera").tag("iPhone")
                        Text("Meta Glasses").tag("glasses")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: streamingModeRaw) { _, newValue in
                        session.streamingMode = newValue == "iPhone" ? .iPhone : .glasses
                    }

                    if streamingModeRaw == "glasses" {
                        NavigationLink("Glasses Connection") {
                            GlassesConnectionView()
                        }
                    }
                }

                Section("Modes") {
                    ForEach(session.modeRouter.availableModes, id: \.id) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                                .frame(width: 24)
                            Text(mode.name)
                            Spacer()
                            if mode.id == session.modeRouter.currentMode.id {
                                Text("Active")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func statusBadge(configured: Bool) -> some View {
        Text(configured ? "Configured" : "Not Set")
            .font(.caption)
            .foregroundColor(configured ? .green : .red)
    }
}

#Preview {
    SettingsView()
        .environmentObject(GeminiSessionViewModel())
}

import MWDATCore
import SwiftUI

/// UI for pairing and managing Meta Ray-Ban Smart Glasses via DAT SDK.
struct GlassesConnectionView: View {
    @ObservedObject var glasses: GlassesCameraManager

    var body: some View {
        List {
            Section {
                HStack {
                    Text("SDK Status")
                    Spacer()
                    Text(registrationLabel)
                        .foregroundColor(registrationColor)
                }

                HStack {
                    Text("Devices")
                    Spacer()
                    Text(glasses.devices.isEmpty ? "None" : "\(glasses.devices.count)")
                        .foregroundColor(glasses.devices.isEmpty ? .secondary : .primary)
                }

                HStack {
                    Text("Active Device")
                    Spacer()
                    Image(systemName: glasses.hasActiveDevice ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(glasses.hasActiveDevice ? .green : .secondary)
                }

                HStack {
                    Text("Stream")
                    Spacer()
                    Text(streamStateLabel)
                        .foregroundColor(glasses.streamState == .streaming ? .green : .secondary)
                }
            } header: {
                Text("Status")
            }

            Section {
                switch glasses.registrationState {
                case .unavailable:
                    Label("Wearables SDK not available. Make sure Meta AI app is installed with Developer Mode enabled.",
                          systemImage: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                case .available:
                    Button {
                        glasses.pair()
                    } label: {
                        Label("Pair Glasses", systemImage: "eyeglasses")
                    }
                    Text("Opens Meta AI app to connect your glasses. You only need to do this once.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .registering:
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Complete pairing in Meta AI app...")
                            .foregroundColor(.secondary)
                    }
                case .registered:
                    Label("Paired", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Button("Unpair Glasses", role: .destructive) {
                        glasses.unpair()
                    }
                @unknown default:
                    EmptyView()
                }
            } header: {
                Text("Pairing")
            } footer: {
                if glasses.registrationState == .registered && glasses.devices.isEmpty {
                    Text("Paired but no devices visible. Make sure your glasses are on, connected in the Meta AI app, and Developer Mode is enabled.")
                }
            }

            if !glasses.devices.isEmpty {
                Section("Devices") {
                    ForEach(glasses.devices, id: \.self) { device in
                        HStack {
                            Image(systemName: "eyeglasses")
                            Text(device)
                            Spacer()
                            if glasses.hasActiveDevice {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }

            if let error = glasses.errorMessage {
                Section("Error") {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Glasses")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var registrationLabel: String {
        switch glasses.registrationState {
        case .unavailable: return "Unavailable"
        case .available: return "Ready to Pair"
        case .registering: return "Pairing..."
        case .registered: return "Paired"
        @unknown default: return "Unknown"
        }
    }

    private var registrationColor: Color {
        switch glasses.registrationState {
        case .unavailable: return .red
        case .available: return .orange
        case .registering: return .orange
        case .registered: return .green
        @unknown default: return .secondary
        }
    }

    private var streamStateLabel: String {
        switch glasses.streamState {
        case .stopped: return "Stopped"
        case .waitingForDevice: return "Waiting for Device"
        case .starting: return "Starting"
        case .streaming: return "Streaming"
        case .paused: return "Paused"
        case .stopping: return "Stopping"
        @unknown default: return "Unknown"
        }
    }
}

// Preview requires Wearables SDK configured
// #Preview {
//     NavigationStack {
//         GlassesConnectionView(glasses: GlassesCameraManager())
//     }
// }

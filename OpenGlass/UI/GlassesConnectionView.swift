import MWDATCore
import SwiftUI

/// UI for pairing and managing Meta Ray-Ban Smart Glasses via DAT SDK.
struct GlassesConnectionView: View {
    @EnvironmentObject private var sessionViewModel: GeminiSessionViewModel

    private var glasses: GlassesCameraManager {
        sessionViewModel.glassesCamera
    }

    var body: some View {
        List {
            Section("Registration") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(registrationLabel)
                        .foregroundColor(registrationColor)
                }

                switch glasses.registrationState {
                case .unavailable:
                    Text("Wearables SDK not available")
                        .foregroundColor(.secondary)
                case .available:
                    Button("Pair Glasses") {
                        glasses.pair()
                    }
                case .registering:
                    HStack {
                        ProgressView()
                            .padding(.trailing, 8)
                        Text("Waiting for Meta AI app...")
                            .foregroundColor(.secondary)
                    }
                case .registered:
                    Button("Unpair Glasses", role: .destructive) {
                        glasses.unpair()
                    }
                @unknown default:
                    EmptyView()
                }
            }

            if glasses.registrationState == .registered {
                Section("Devices") {
                    if glasses.devices.isEmpty {
                        Text("No devices found")
                            .foregroundColor(.secondary)
                    } else {
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

                Section("Stream") {
                    HStack {
                        Text("State")
                        Spacer()
                        Text(streamStateLabel)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Connected")
                        Spacer()
                        Image(systemName: glasses.isConnected ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(glasses.isConnected ? .green : .secondary)
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
        case .available: return "Not Registered"
        case .registering: return "Registering..."
        case .registered: return "Registered"
        @unknown default: return "Unknown"
        }
    }

    private var registrationColor: Color {
        switch glasses.registrationState {
        case .unavailable: return .red
        case .available: return .secondary
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

#Preview {
    NavigationStack {
        GlassesConnectionView()
    }
}

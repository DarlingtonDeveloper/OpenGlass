import MWDATCamera
import MWDATCore
import UIKit

/// Camera source for Meta Ray-Ban Smart Glasses via the DAT SDK.
///
/// Uses `StreamSession` with `AutoDeviceSelector` to receive video frames
/// from paired glasses and convert them to `UIImage` for the Gemini pipeline.
@MainActor
class GlassesCameraManager: ObservableObject {
    var onFrameCaptured: ((UIImage) -> Void)?

    @Published var isConnected = false
    @Published var registrationState: RegistrationState = .unavailable
    @Published var streamState: StreamSessionState = .stopped
    @Published var devices: [DeviceIdentifier] = []
    @Published var hasActiveDevice = false
    @Published var errorMessage: String?

    private let wearables: any WearablesInterface
    private var deviceSelector: AutoDeviceSelector?
    private var streamSession: StreamSession?

    // Listener tokens
    private var videoFrameToken: (any AnyListenerToken)?
    private var stateToken: (any AnyListenerToken)?
    private var errorToken: (any AnyListenerToken)?

    // Observation tasks
    private var registrationTask: Task<Void, Never>?
    private var devicesTask: Task<Void, Never>?
    private var activeDeviceTask: Task<Void, Never>?

    init() {
        self.wearables = Wearables.shared
        self.registrationState = wearables.registrationState
        self.devices = wearables.devices
        startObserving()
    }

    // MARK: - CameraSource

    func start() {
        NSLog("[GlassesCamera] Starting stream")
        Task {
            await startStreaming()
        }
    }

    func stop() {
        NSLog("[GlassesCamera] Stopping stream")
        Task {
            await stopStreaming()
        }
    }

    // MARK: - Pairing

    func pair() {
        guard registrationState != .registering else { return }
        Task {
            do {
                try await wearables.startRegistration()
            } catch {
                errorMessage = "Registration failed: \(error)"
                NSLog("[GlassesCamera] Registration error: %@", "\(error)")
            }
        }
    }

    func unpair() {
        Task {
            do {
                try await wearables.startUnregistration()
            } catch {
                errorMessage = "Unregistration failed: \(error)"
                NSLog("[GlassesCamera] Unregistration error: %@", "\(error)")
            }
        }
    }

    // MARK: - Streaming

    private func startStreaming() async {
        NSLog("[GlassesCamera] startStreaming — registration: %@, devices: %d, sdk registration: %@",
              registrationState.description, devices.count,
              wearables.registrationState.description)

        // Skip permission check — AutoDeviceSelector and StreamSession handle
        // waiting for a device. Permission will be requested once a device connects.
        // Calling startRegistration() when already registered causes state churn.

        let selector = AutoDeviceSelector(wearables: wearables)
        self.deviceSelector = selector

        let config = StreamSessionConfig(
            videoCodec: .raw,
            resolution: .low,
            frameRate: 24
        )
        let session = StreamSession(streamSessionConfig: config, deviceSelector: selector)
        self.streamSession = session
        NSLog("[GlassesCamera] StreamSession created — codec: raw, resolution: low, fps: 24")

        attachListeners(session)

        // Monitor active device and request camera permission when one connects
        activeDeviceTask = Task { [weak self] in
            var permissionRequested = false
            for await device in selector.activeDeviceStream() {
                guard let self, !Task.isCancelled else { break }
                let connected = device != nil
                NSLog("[GlassesCamera] Active device changed: %@", device ?? "nil")
                self.hasActiveDevice = connected
                self.isConnected = connected

                // Request camera permission once when first device connects
                if connected && !permissionRequested {
                    permissionRequested = true
                    do {
                        let status = try await self.wearables.checkPermissionStatus(.camera)
                        NSLog("[GlassesCamera] Camera permission: %@", "\(status)")
                        if status != .granted {
                            let result = try await self.wearables.requestPermission(.camera)
                            NSLog("[GlassesCamera] Camera permission request result: %@", "\(result)")
                        }
                    } catch {
                        NSLog("[GlassesCamera] Camera permission check failed: %@ — stream may still work", "\(error)")
                    }
                }
            }
        }

        NSLog("[GlassesCamera] Starting session...")
        await session.start()
        NSLog("[GlassesCamera] session.start() returned — state: %@", "\(session.state)")
    }

    private func stopStreaming() async {
        videoFrameToken = nil
        stateToken = nil
        errorToken = nil
        activeDeviceTask?.cancel()
        activeDeviceTask = nil

        if let session = streamSession {
            await session.stop()
        }
        streamSession = nil
        deviceSelector = nil
        streamState = .stopped
        isConnected = false
        hasActiveDevice = false
    }

    private var frameCount = 0

    private func attachListeners(_ session: StreamSession) {
        frameCount = 0

        videoFrameToken = session.videoFramePublisher.listen { [weak self] videoFrame in
            let image = videoFrame.makeUIImage()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.frameCount += 1
                if self.frameCount <= 5 || self.frameCount % 100 == 0 {
                    NSLog("[GlassesCamera] Frame #%d received — image: %@",
                          self.frameCount, image != nil ? "\(Int(image!.size.width))x\(Int(image!.size.height))" : "nil")
                }
                guard let image else { return }
                self.onFrameCaptured?(image)
            }
        }

        stateToken = session.statePublisher.listen { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                NSLog("[GlassesCamera] Stream state → %@", "\(state)")
                self.streamState = state
            }
        }

        errorToken = session.errorPublisher.listen { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.errorMessage = "Stream error: \(error)"
                NSLog("[GlassesCamera] Stream error: %@", "\(error)")
            }
        }
    }

    // MARK: - Observation

    private func startObserving() {
        registrationTask = Task { [weak self] in
            guard let self else { return }
            for await state in self.wearables.registrationStateStream() {
                guard !Task.isCancelled else { break }
                self.registrationState = state
            }
        }

        devicesTask = Task { [weak self] in
            guard let self else { return }
            for await devices in self.wearables.devicesStream() {
                guard !Task.isCancelled else { break }
                self.devices = devices
            }
        }
    }

    deinit {
        registrationTask?.cancel()
        devicesTask?.cancel()
        activeDeviceTask?.cancel()
    }
}

// MARK: - CameraSource conformance

extension GlassesCameraManager: CameraSource {}

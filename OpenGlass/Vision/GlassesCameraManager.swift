import MWDATCamera
import MWDATCore
import UIKit

/// Camera source for Meta Ray-Ban Smart Glasses via the DAT SDK.
///
/// Creates `AutoDeviceSelector` and `StreamSession` at init and keeps them alive.
/// Matches the pattern from Meta's CameraAccess sample app.
@MainActor
class GlassesCameraManager: ObservableObject {
    var onFrameCaptured: ((UIImage) -> Void)?

    @Published var isConnected = false
    @Published var registrationState: RegistrationState
    @Published var streamState: StreamSessionState = .stopped
    @Published var devices: [DeviceIdentifier] = []
    @Published var hasActiveDevice = false
    @Published var errorMessage: String?

    private let wearables: WearablesInterface
    private let deviceSelector: AutoDeviceSelector
    private var streamSession: StreamSession

    // Listener tokens — attached once at init
    private var videoFrameToken: AnyListenerToken?
    private var stateToken: AnyListenerToken?
    private var errorToken: AnyListenerToken?

    // Observation tasks
    private var registrationTask: Task<Void, Never>?
    private var devicesTask: Task<Void, Never>?
    private var deviceMonitorTask: Task<Void, Never>?

    private var frameCount = 0

    init() {
        let wearables = Wearables.shared
        self.wearables = wearables
        self.registrationState = wearables.registrationState
        self.devices = wearables.devices

        // Create device selector and stream session once — keep alive
        let selector = AutoDeviceSelector(wearables: wearables)
        self.deviceSelector = selector

        let config = StreamSessionConfig(
            videoCodec: .raw,
            resolution: .low,
            frameRate: 24
        )
        self.streamSession = StreamSession(streamSessionConfig: config, deviceSelector: selector)

        NSLog("[GlassesCamera] Init — registration: %@, devices: %d",
              wearables.registrationState.description, wearables.devices.count)

        // Monitor active device — starts immediately
        deviceMonitorTask = Task { [weak self] in
            for await device in selector.activeDeviceStream() {
                guard let self, !Task.isCancelled else { break }
                let connected = device != nil
                NSLog("[GlassesCamera] Active device changed: %@", device ?? "nil")
                self.hasActiveDevice = connected
                self.isConnected = connected
            }
        }

        // Attach stream listeners once
        attachListeners()

        // Watch registration state
        registrationTask = Task { [weak self] in
            guard let self else { return }
            for await state in wearables.registrationStateStream() {
                guard !Task.isCancelled else { break }
                NSLog("[GlassesCamera] Registration state → %@", state.description)
                self.registrationState = state
            }
        }

        // Watch devices
        devicesTask = Task { [weak self] in
            guard let self else { return }
            for await devices in wearables.devicesStream() {
                guard !Task.isCancelled else { break }
                NSLog("[GlassesCamera] Devices changed: %d device(s)", devices.count)
                self.devices = devices
            }
        }
    }

    // MARK: - CameraSource

    func start() {
        NSLog("[GlassesCamera] Starting stream — registration: %@, devices: %d, activeDevice: %@",
              registrationState.description, devices.count,
              hasActiveDevice ? "yes" : "no")

        // Request camera permission if a device is available
        if hasActiveDevice {
            Task {
                await requestCameraPermissionAndStart()
            }
        } else {
            // Start anyway — session will wait for device
            Task {
                await streamSession.start()
                NSLog("[GlassesCamera] session.start() returned — state: %@", "\(streamSession.state)")
            }
        }
    }

    func stop() {
        NSLog("[GlassesCamera] Stopping stream")
        Task {
            await streamSession.stop()
        }
    }

    // MARK: - Pairing

    func pair() {
        guard registrationState != .registering else { return }
        NSLog("[GlassesCamera] Starting registration...")
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

    // MARK: - Private

    private func requestCameraPermissionAndStart() async {
        do {
            let status = try await wearables.checkPermissionStatus(.camera)
            NSLog("[GlassesCamera] Camera permission: %@", "\(status)")
            if status != .granted {
                let result = try await wearables.requestPermission(.camera)
                NSLog("[GlassesCamera] Camera permission request: %@", "\(result)")
                guard result == .granted else {
                    errorMessage = "Camera permission denied"
                    return
                }
            }
        } catch {
            NSLog("[GlassesCamera] Permission check failed: %@ — starting anyway", "\(error)")
        }

        await streamSession.start()
        NSLog("[GlassesCamera] session.start() returned — state: %@", "\(streamSession.state)")
    }

    private func attachListeners() {
        frameCount = 0

        videoFrameToken = streamSession.videoFramePublisher.listen { [weak self] videoFrame in
            let image = videoFrame.makeUIImage()
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.frameCount += 1
                if self.frameCount <= 5 || self.frameCount % 100 == 0 {
                    NSLog("[GlassesCamera] Frame #%d — %@",
                          self.frameCount,
                          image != nil ? "\(Int(image!.size.width))x\(Int(image!.size.height))" : "nil")
                }
                guard let image else { return }
                self.onFrameCaptured?(image)
            }
        }

        stateToken = streamSession.statePublisher.listen { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                NSLog("[GlassesCamera] Stream state → %@", "\(state)")
                self.streamState = state
            }
        }

        errorToken = streamSession.errorPublisher.listen { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.errorMessage = "Stream error: \(error)"
                NSLog("[GlassesCamera] Stream error: %@", "\(error)")
            }
        }
    }

    deinit {
        registrationTask?.cancel()
        devicesTask?.cancel()
        deviceMonitorTask?.cancel()
    }
}

// MARK: - CameraSource conformance

extension GlassesCameraManager: CameraSource {}

import UIKit

/// Stub camera source for Meta Ray-Ban smart glasses via DAT SDK.
///
/// TODO: Integrate Meta DAT SDK when available:
/// 1. Import DATDeviceKit framework
/// 2. Discover and pair glasses via DATDeviceManager
/// 3. Start camera stream via DATCameraSession
/// 4. Convert DAT video frames to UIImage and call onFrameCaptured
///
/// For now this is a protocol-conforming stub that does nothing.
class GlassesCameraManager: CameraSource {
    var onFrameCaptured: ((UIImage) -> Void)?

    /// Whether glasses are currently paired and connected.
    private(set) var isConnected = false

    func start() {
        NSLog("[GlassesCamera] Start requested — DAT SDK not yet integrated")
        // TODO: DATDeviceManager.shared.startCameraStream { [weak self] frame in
        //     guard let image = frame.toUIImage() else { return }
        //     self?.onFrameCaptured?(image)
        // }
    }

    func stop() {
        NSLog("[GlassesCamera] Stop requested — DAT SDK not yet integrated")
        // TODO: DATDeviceManager.shared.stopCameraStream()
    }

    /// Attempt to pair with nearby glasses.
    /// TODO: Implement via DAT SDK pairing flow
    func pair() async -> Bool {
        NSLog("[GlassesCamera] Pairing requested — DAT SDK not yet integrated")
        return false
    }

    /// Disconnect from paired glasses.
    func unpair() {
        isConnected = false
        NSLog("[GlassesCamera] Unpaired")
    }
}

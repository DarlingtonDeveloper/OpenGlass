import UIKit
@testable import OpenGlass

// MARK: - MockCameraSource
// Conforms to CameraSource protocol; emits test frames on demand.

class MockCameraSource: CameraSource {
    var onFrameCaptured: ((UIImage) -> Void)?

    var startCallCount = 0
    var stopCallCount = 0
    var isRunning = false

    func start() {
        startCallCount += 1
        isRunning = true
    }

    func stop() {
        stopCallCount += 1
        isRunning = false
    }

    /// Emit a test frame to the onFrameCaptured callback.
    func emitFrame(_ image: UIImage? = nil) {
        let frame = image ?? Self.createTestImage()
        onFrameCaptured?(frame)
    }

    /// Creates a minimal 1x1 test UIImage.
    static func createTestImage(width: Int = 1, height: Int = 1, color: UIColor = .red) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

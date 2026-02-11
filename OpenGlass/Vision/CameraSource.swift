import UIKit

/// Common protocol for camera sources (iPhone back camera, Meta glasses, etc.)
protocol CameraSource: AnyObject {
    var onFrameCaptured: ((UIImage) -> Void)? { get set }
    func start()
    func stop()
}

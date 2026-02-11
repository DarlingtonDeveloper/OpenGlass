import Foundation
import UIKit

/// Throttles camera frames to a configurable interval before forwarding.
class FrameThrottler {
    var onThrottledFrame: ((UIImage) -> Void)?

    private var lastFrameTime: Date = .distantPast
    private let interval: TimeInterval

    /// - Parameter interval: Minimum seconds between forwarded frames (default: from config).
    init(interval: TimeInterval = OpenGlassConfig.videoFrameInterval) {
        self.interval = interval
    }

    /// Call with every camera frame. Only forwards if enough time has passed.
    func submit(_ image: UIImage) {
        let now = Date()
        guard now.timeIntervalSince(lastFrameTime) >= interval else { return }
        lastFrameTime = now
        onThrottledFrame?(image)
    }

    /// Reset the throttle timer (e.g. on session restart).
    func reset() {
        lastFrameTime = .distantPast
    }
}

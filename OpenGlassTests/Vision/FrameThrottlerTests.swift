import XCTest
@testable import OpenGlass

final class FrameThrottlerTests: XCTestCase {

    // MARK: - Basic Throttling

    func test_firstFrame_alwaysPasses() {
        let throttler = FrameThrottler(interval: 1.0)
        var receivedCount = 0
        throttler.onThrottledFrame = { _ in receivedCount += 1 }

        throttler.submit(MockCameraSource.createTestImage())
        XCTAssertEqual(receivedCount, 1)
    }

    func test_rapidFrames_blocked() {
        let throttler = FrameThrottler(interval: 1.0)
        var receivedCount = 0
        throttler.onThrottledFrame = { _ in receivedCount += 1 }

        let image = MockCameraSource.createTestImage()
        throttler.submit(image) // passes
        throttler.submit(image) // blocked
        throttler.submit(image) // blocked
        throttler.submit(image) // blocked

        XCTAssertEqual(receivedCount, 1)
    }

    func test_frameAfterInterval_passes() {
        let throttler = FrameThrottler(interval: 0.05) // 50ms for fast test
        var receivedCount = 0
        throttler.onThrottledFrame = { _ in receivedCount += 1 }

        let image = MockCameraSource.createTestImage()
        throttler.submit(image) // passes
        XCTAssertEqual(receivedCount, 1)

        // Wait for interval to elapse
        let expectation = expectation(description: "wait for throttle interval")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            throttler.submit(image) // should pass
            XCTAssertEqual(receivedCount, 2)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Different Intervals

    func test_zeroInterval_allFramesPass() {
        let throttler = FrameThrottler(interval: 0.0)
        var receivedCount = 0
        throttler.onThrottledFrame = { _ in receivedCount += 1 }

        let image = MockCameraSource.createTestImage()
        for _ in 0..<5 {
            throttler.submit(image)
        }
        XCTAssertEqual(receivedCount, 5)
    }

    // MARK: - Reset

    func test_reset_clearsTimingSoNextFramePasses() {
        let throttler = FrameThrottler(interval: 100.0) // very long
        var receivedCount = 0
        throttler.onThrottledFrame = { _ in receivedCount += 1 }

        let image = MockCameraSource.createTestImage()
        throttler.submit(image) // passes
        XCTAssertEqual(receivedCount, 1)

        throttler.submit(image) // blocked (100s not elapsed)
        XCTAssertEqual(receivedCount, 1)

        throttler.reset()
        throttler.submit(image) // passes after reset
        XCTAssertEqual(receivedCount, 2)
    }

    // MARK: - No Callback

    func test_submit_withNoCallback_doesNotCrash() {
        let throttler = FrameThrottler(interval: 0.0)
        // onThrottledFrame is nil
        throttler.submit(MockCameraSource.createTestImage())
        // No crash = pass
    }
}

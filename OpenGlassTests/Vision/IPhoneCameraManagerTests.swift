import XCTest
@testable import OpenGlass

final class IPhoneCameraManagerTests: XCTestCase {

    // MARK: - MockCameraSource (protocol conformance)

    func test_mockCameraSource_conformsToProtocol() {
        let mock: CameraSource = MockCameraSource()
        XCTAssertNotNil(mock)
    }

    func test_mockCameraSource_startStop_tracksState() {
        let mock = MockCameraSource()
        XCTAssertFalse(mock.isRunning)

        mock.start()
        XCTAssertTrue(mock.isRunning)
        XCTAssertEqual(mock.startCallCount, 1)

        mock.stop()
        XCTAssertFalse(mock.isRunning)
        XCTAssertEqual(mock.stopCallCount, 1)
    }

    func test_mockCameraSource_emitFrame_callsCallback() {
        let mock = MockCameraSource()
        var received: UIImage?
        mock.onFrameCaptured = { image in
            received = image
        }
        mock.emitFrame()
        XCTAssertNotNil(received)
    }

    func test_mockCameraSource_emitFrame_customImage() {
        let mock = MockCameraSource()
        let testImage = MockCameraSource.createTestImage(width: 5, height: 5, color: .blue)
        var received: UIImage?
        mock.onFrameCaptured = { image in
            received = image
        }
        mock.emitFrame(testImage)
        XCTAssertNotNil(received)
        XCTAssertEqual(received?.size.width, 5)
    }

    func test_mockCameraSource_noCallback_doesNotCrash() {
        let mock = MockCameraSource()
        mock.emitFrame() // no callback set, should not crash
    }

    // MARK: - IPhoneCameraManager exists

    func test_iPhoneCameraManager_conformsToCameraSource() {
        // Verify the class conforms at compile time
        let _: CameraSource = IPhoneCameraManager()
    }
}

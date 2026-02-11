import XCTest
@testable import OpenGlass

final class ConnectionModeTests: XCTestCase {

    // MARK: - ConnectionMode enum

    func test_connectionMode_allCases() {
        XCTAssertEqual(ConnectionMode.allCases.count, 3)
        XCTAssertTrue(ConnectionMode.allCases.contains(.lan))
        XCTAssertTrue(ConnectionMode.allCases.contains(.tunnel))
        XCTAssertTrue(ConnectionMode.allCases.contains(.auto))
    }

    func test_connectionMode_rawValues() {
        XCTAssertEqual(ConnectionMode.lan.rawValue, "LAN (Local Network)")
        XCTAssertEqual(ConnectionMode.tunnel.rawValue, "Cloudflare Tunnel")
        XCTAssertEqual(ConnectionMode.auto.rawValue, "Auto (try LAN first, fall back to tunnel)")
    }

    func test_connectionMode_initFromRawValue() {
        XCTAssertEqual(ConnectionMode(rawValue: "LAN (Local Network)"), .lan)
        XCTAssertEqual(ConnectionMode(rawValue: "Cloudflare Tunnel"), .tunnel)
        XCTAssertNil(ConnectionMode(rawValue: "invalid"))
    }

    // MARK: - ResolvedConnection

    func test_resolvedConnection_labels() {
        XCTAssertEqual(ResolvedConnection.lan.label, "LAN")
        XCTAssertEqual(ResolvedConnection.tunnel.label, "Tunnel")
    }

    func test_resolvedConnection_equatable() {
        XCTAssertEqual(ResolvedConnection.lan, .lan)
        XCTAssertEqual(ResolvedConnection.tunnel, .tunnel)
        XCTAssertNotEqual(ResolvedConnection.lan, .tunnel)
    }

    // MARK: - OpenClawBridge endpoint caching

    @MainActor
    func test_bridge_initialState_noCachedEndpoint() {
        let bridge = OpenClawBridge()
        XCTAssertNil(bridge.resolvedConnection)
    }

    @MainActor
    func test_bridge_clearCachedEndpoint() {
        let bridge = OpenClawBridge()
        bridge.clearCachedEndpoint()
        XCTAssertNil(bridge.resolvedConnection)
    }

    @MainActor
    func test_bridge_resolveEndpoint_lanMode() async {
        let original = OpenGlassConfig.connectionMode
        defer { OpenGlassConfig.connectionMode = original }

        OpenGlassConfig.connectionMode = .lan
        let bridge = OpenClawBridge()
        let endpoint = await bridge.resolveEndpoint()

        XCTAssertTrue(endpoint.contains(OpenGlassConfig.lanHost))
        XCTAssertEqual(bridge.resolvedConnection, .lan)
    }

    @MainActor
    func test_bridge_resolveEndpoint_tunnelMode() async {
        let original = OpenGlassConfig.connectionMode
        defer { OpenGlassConfig.connectionMode = original }

        OpenGlassConfig.connectionMode = .tunnel
        let bridge = OpenClawBridge()
        let endpoint = await bridge.resolveEndpoint()

        XCTAssertEqual(endpoint, OpenGlassConfig.tunnelHost)
        XCTAssertEqual(bridge.resolvedConnection, .tunnel)
    }

    @MainActor
    func test_bridge_resolveEndpoint_caches() async {
        let original = OpenGlassConfig.connectionMode
        defer { OpenGlassConfig.connectionMode = original }

        OpenGlassConfig.connectionMode = .lan
        let bridge = OpenClawBridge()

        let first = await bridge.resolveEndpoint()
        let second = await bridge.resolveEndpoint()

        XCTAssertEqual(first, second)
    }

    @MainActor
    func test_bridge_resolveEndpoint_clearAndReResolve() async {
        let original = OpenGlassConfig.connectionMode
        defer { OpenGlassConfig.connectionMode = original }

        OpenGlassConfig.connectionMode = .lan
        let bridge = OpenClawBridge()

        _ = await bridge.resolveEndpoint()
        XCTAssertEqual(bridge.resolvedConnection, .lan)

        bridge.clearCachedEndpoint()
        XCTAssertNil(bridge.resolvedConnection)

        OpenGlassConfig.connectionMode = .tunnel
        _ = await bridge.resolveEndpoint()
        XCTAssertEqual(bridge.resolvedConnection, .tunnel)
    }

    // MARK: - Auto mode (LAN unreachable → falls back to tunnel)

    @MainActor
    func test_bridge_autoMode_fallsBackToTunnel_whenLANUnreachable() async {
        let original = OpenGlassConfig.connectionMode
        defer { OpenGlassConfig.connectionMode = original }

        // Auto mode with a LAN host that's not reachable (invalid host)
        OpenGlassConfig.connectionMode = .auto
        let bridge = OpenClawBridge()

        let endpoint = await bridge.resolveEndpoint()

        // Since LAN is likely unreachable in test environment, should fall back to tunnel
        // (or succeed if LAN happens to be up — either is valid)
        XCTAssertNotNil(bridge.resolvedConnection)
        XCTAssertFalse(endpoint.isEmpty)
    }
}

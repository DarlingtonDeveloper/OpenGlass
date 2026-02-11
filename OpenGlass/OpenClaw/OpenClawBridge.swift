// OpenGlass - OpenClawBridge.swift

import Foundation

/// HTTP client for communicating with the OpenClaw Gateway on the LAN.
/// TODO: Discover gateway via mDNS/Bonjour (.local hostname)
/// TODO: Health check endpoint to verify connectivity
/// TODO: Send skill invocation requests (POST)
/// TODO: Parse skill results and return to caller
/// TODO: Handle timeouts and gateway unavailability
class OpenClawBridge {
    var gatewayURL: URL?

    // TODO: discoverGateway() — mDNS lookup
    // TODO: invokeSkill(name:params:) async throws -> SkillResult
    // TODO: checkHealth() async -> Bool
}

import MWDATCore
import SwiftUI

@main
struct OpenGlassApp: App {
    @StateObject private var sessionViewModel: GeminiSessionViewModel

    init() {
        // Configure Wearables SDK BEFORE creating any view models that use it
        do {
            try Wearables.configure()
            NSLog("[OpenGlass] Wearables SDK configured — registration: %@, devices: %d",
                  Wearables.shared.registrationState.description,
                  Wearables.shared.devices.count)
        } catch {
            NSLog("[OpenGlass] Wearables.configure() FAILED: %@", "\(error)")
        }

        // Create view model AFTER configure() so GlassesCameraManager sees the SDK
        self._sessionViewModel = StateObject(wrappedValue: GeminiSessionViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionViewModel)
                .environmentObject(sessionViewModel.modeRouter)

            // Registration callback handler — must always be in the view hierarchy
            // (matches CameraAccess sample app pattern)
            RegistrationCallbackView(glassesCamera: sessionViewModel.glassesCamera)
        }
    }
}

/// Invisible view that handles deep link callbacks from Meta AI app during
/// DAT SDK registration and permission flows.
private struct RegistrationCallbackView: View {
    let glassesCamera: GlassesCameraManager

    var body: some View {
        EmptyView()
            .onOpenURL { url in
                NSLog("[OpenGlass] onOpenURL: %@", url.absoluteString)
                guard
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                    components.queryItems?.contains(where: { $0.name == "metaWearablesAction" }) == true
                else {
                    NSLog("[OpenGlass] URL not a DAT SDK callback — ignoring")
                    return
                }
                Task {
                    do {
                        let handled = try await Wearables.shared.handleUrl(url)
                        NSLog("[OpenGlass] handleUrl result: %@", handled ? "handled" : "not handled")
                    } catch {
                        NSLog("[OpenGlass] handleUrl error: %@", "\(error)")
                        glassesCamera.errorMessage = "Registration callback failed: \(error.localizedDescription)"
                    }
                }
            }
    }
}

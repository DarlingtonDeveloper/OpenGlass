import Foundation
import SwiftUI

enum StreamingMode {
    case iPhone
    case glasses
}

@MainActor
class GeminiSessionViewModel: ObservableObject {
    @Published var isGeminiActive: Bool = false
    @Published var connectionState: GeminiConnectionState = .disconnected
    @Published var isModelSpeaking: Bool = false
    @Published var errorMessage: String?
    @Published var userTranscript: String = ""
    @Published var aiTranscript: String = ""
    @Published var toolCallStatus: ToolCallStatus = .idle
    @Published var openClawConnectionState: OpenClawConnectionState = .notConfigured
    @Published var detectedQRCodes: [QRContent] = []
    @Published var reconnecting: Bool = false

    let modeRouter = ModeRouter()
    private let geminiService = GeminiLiveService()
    let openClawBridge = OpenClawBridge()
    private var toolCallRouter: ToolCallRouter?
    private let audioManager = AudioManager()
    private let frameThrottler = FrameThrottler()
    private let qrDetector = QRDetector()
    private var stateObservation: Task<Void, Never>?

    var streamingMode: StreamingMode = .glasses

    // Camera sources
    let iPhoneCamera = IPhoneCameraManager()
    let glassesCamera = GlassesCameraManager()

    init() {
        // Wire mode changes to session reconnect
        modeRouter.onModeChanged = { [weak self] mode in
            guard let self else { return }
            Task { @MainActor in
                if self.isGeminiActive {
                    NSLog("[Session] Mode changed to %@, reconnecting...", mode.id)
                    self.stopSession()
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self.startSession()
                }
            }
        }
    }

    func startSession() async {
        guard !isGeminiActive else { return }

        guard OpenGlassConfig.isConfigured else {
            errorMessage = "Gemini API key not configured. See Secrets.example.swift."
            return
        }

        isGeminiActive = true

        let currentMode = modeRouter.currentMode

        // Configure Gemini with current mode's instructions and tools
        geminiService.configure(
            systemInstruction: currentMode.systemInstruction,
            toolDeclarations: currentMode.toolDeclarations
        )

        // Wire audio
        audioManager.onAudioCaptured = { [weak self] data in
            guard let self else { return }
            Task { @MainActor in
                if self.streamingMode == .iPhone && self.geminiService.isModelSpeaking { return }
                self.geminiService.sendAudio(data: data)
            }
        }

        geminiService.onAudioReceived = { [weak self] data in
            self?.audioManager.playAudio(data: data)
        }

        geminiService.onInterrupted = { [weak self] in
            self?.audioManager.stopPlayback()
        }

        geminiService.onTurnComplete = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.userTranscript = ""
            }
        }

        geminiService.onInputTranscription = { [weak self] text in
            guard let self else { return }
            Task { @MainActor in
                self.userTranscript += text
                self.aiTranscript = ""
                // Check for auto mode switching on transcript
                self.modeRouter.checkAutoSwitch(transcript: self.userTranscript, frame: nil)
            }
        }

        geminiService.onOutputTranscription = { [weak self] text in
            guard let self else { return }
            Task { @MainActor in
                self.aiTranscript += text
            }
        }

        geminiService.onDisconnected = { [weak self] reason in
            guard let self else { return }
            Task { @MainActor in
                guard self.isGeminiActive else { return }
                // Don't stop session — let reconnection logic handle it
                if !self.geminiService.reconnecting {
                    self.stopSession()
                    self.errorMessage = "Connection lost: \(reason ?? "Unknown error")"
                }
            }
        }

        geminiService.onReconnected = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                NSLog("[Session] Reconnected — re-sending setup for mode %@", self.modeRouter.currentMode.id)
                // Re-configure with current mode
                self.geminiService.configure(
                    systemInstruction: self.modeRouter.currentMode.systemInstruction,
                    toolDeclarations: self.modeRouter.currentMode.toolDeclarations
                )
                // Re-start audio capture
                do {
                    try self.audioManager.startCapture()
                } catch {
                    NSLog("[Session] Failed to restart audio after reconnect: %@", error.localizedDescription)
                }
                // Re-start camera
                let activeCamera: CameraSource = self.streamingMode == .iPhone ? self.iPhoneCamera : self.glassesCamera
                activeCamera.start()
            }
        }

        // OpenClaw
        await openClawBridge.checkConnection()
        openClawBridge.resetSession()

        toolCallRouter = ToolCallRouter(bridge: openClawBridge)

        geminiService.onToolCall = { [weak self] toolCall in
            guard let self else { return }
            Task { @MainActor in
                for call in toolCall.functionCalls {
                    self.toolCallRouter?.handleToolCall(call) { [weak self] response in
                        self?.geminiService.sendToolResponse(response)
                    }
                }
            }
        }

        geminiService.onToolCallCancellation = { [weak self] cancellation in
            guard let self else { return }
            Task { @MainActor in
                self.toolCallRouter?.cancelToolCalls(ids: cancellation.ids)
            }
        }

        // State observation
        stateObservation = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else { break }
                self.connectionState = self.geminiService.connectionState
                self.isModelSpeaking = self.geminiService.isModelSpeaking
                self.reconnecting = self.geminiService.reconnecting
                self.toolCallStatus = self.openClawBridge.lastToolCallStatus
                self.openClawConnectionState = self.openClawBridge.connectionState
            }
        }

        // Wire frame throttler to Gemini
        frameThrottler.reset()
        frameThrottler.onThrottledFrame = { [weak self] image in
            guard let self else { return }
            self.geminiService.sendVideoFrame(image: image)

            // QR detection on throttled frames
            let codes = self.qrDetector.scan(image)
            Task { @MainActor in
                self.detectedQRCodes = codes
                // Check auto-switch with frame
                if !codes.isEmpty {
                    self.modeRouter.checkAutoSwitch(transcript: "", frame: image)
                }
            }
        }

        // Wire active camera to throttler
        let activeCamera: CameraSource = streamingMode == .iPhone ? iPhoneCamera : glassesCamera
        activeCamera.onFrameCaptured = { [weak self] image in
            self?.frameThrottler.submit(image)
        }

        // Audio setup
        do {
            try audioManager.setupAudioSession(useIPhoneMode: streamingMode == .iPhone)
        } catch {
            errorMessage = "Audio setup failed: \(error.localizedDescription)"
            isGeminiActive = false
            return
        }

        // Connect
        let setupOk = await geminiService.connect()

        if !setupOk {
            let msg: String
            if case .error(let err) = geminiService.connectionState {
                msg = err
            } else {
                msg = "Failed to connect to Gemini"
            }
            errorMessage = msg
            geminiService.disconnect()
            stateObservation?.cancel()
            stateObservation = nil
            isGeminiActive = false
            connectionState = .disconnected
            return
        }

        // Start mic + camera
        do {
            try audioManager.startCapture()
        } catch {
            errorMessage = "Mic capture failed: \(error.localizedDescription)"
            geminiService.disconnect()
            stateObservation?.cancel()
            stateObservation = nil
            isGeminiActive = false
            connectionState = .disconnected
            return
        }

        activeCamera.start()
    }

    func stopSession() {
        toolCallRouter?.cancelAll()
        toolCallRouter = nil
        audioManager.stopCapture()
        geminiService.disconnect()
        iPhoneCamera.stop()
        glassesCamera.stop()
        stateObservation?.cancel()
        stateObservation = nil
        isGeminiActive = false
        connectionState = .disconnected
        isModelSpeaking = false
        userTranscript = ""
        aiTranscript = ""
        toolCallStatus = .idle
        detectedQRCodes = []
    }
}

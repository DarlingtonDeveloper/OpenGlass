# OpenGlass 🕶️ — Project Specification

**Version:** 0.1 (Draft)
**Author:** Mike
**Date:** 11 February 2026
**Status:** Planning

---

## Vision

OpenGlass is a real-time AI-powered smart glasses interface that connects Meta Ray-Ban glasses to Gemini Live and OpenClaw, turning them into a personal AI companion with eyes, ears, and hands. Built as a Swift iOS app, it goes beyond basic voice+vision by layering on use cases like real-time Mandarin translation, QR code → action pipelines, contextual scene understanding, and agentic task execution.

Inspired by [VisionClaw](https://github.com/sseanliu/VisionClaw) by Sean Liu. OpenGlass takes the same proven Gemini Live + OpenClaw foundation and extends it with a richer use-case layer and cleaner architecture.

## Architecture Overview

```
Meta Ray-Ban Glasses (or iPhone camera fallback)
       │
       │  video frames (DAT SDK, 24fps) + mic audio
       ▼
┌─────────────────────────────────────────────────┐
│              OpenGlass iOS App (Swift)           │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Vision   │  │  Audio   │  │  Mode Router  │  │
│  │ Pipeline │  │ Pipeline │  │               │  │
│  │          │  │          │  │ • Assistant   │  │
│  │ • Frames │  │ • Mic In │  │ • Translator  │  │
│  │   @1fps  │  │   16kHz  │  │ • QR Scanner  │  │
│  │ • JPEG   │  │   PCM    │  │ • Spotter     │  │
│  │   encode │  │   chunks │  │ • Custom...   │  │
│  └────┬─────┘  └────┬─────┘  └───────┬───────┘  │
│       │             │                │           │
│       ▼             ▼                ▼           │
│  ┌──────────────────────────────────────────┐    │
│  │         Gemini Live WebSocket            │    │
│  │     (vision + audio + tool calling)      │    │
│  └──────────────────┬───────────────────────┘    │
│                     │                            │
│       ┌─────────────┼─────────────┐              │
│       ▼             ▼             ▼              │
│  Audio Out     Tool Calls    Transcript          │
│  (speaker)         │         (on-screen)         │
│                    ▼                             │
│  ┌──────────────────────────────────────────┐    │
│  │         OpenClaw Gateway (LAN)           │    │
│  │    http://<mac>.local:18789              │    │
│  │    56+ skills: web, messaging, smart     │    │
│  │    home, lists, reminders, etc.          │    │
│  └──────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

## Core Components

### 1. Vision Pipeline
- Captures video frames from Meta Ray-Ban glasses via the DAT (Direct Audio Transfer) SDK, or falls back to the iPhone's rear camera
- Throttles to ~1 fps for Gemini consumption (configurable)
- JPEG-encodes each frame at 80% quality, ~100KB target
- Feeds frames into the Gemini Live WebSocket as inline image parts

### 2. Audio Pipeline
- Captures microphone audio at 16kHz mono PCM (from glasses mic or iPhone mic)
- Streams audio chunks to Gemini Live in real-time
- Receives audio responses from Gemini and plays through the glasses speaker (or iPhone speaker)
- Handles echo cancellation and noise suppression via AVAudioEngine

### 3. Mode Router
- Central state machine that determines the current operating mode
- Each mode defines its own system instruction, tool set, and UI overlay
- Modes can be switched via voice command ("switch to translator mode") or UI picker
- Only one mode active at a time; clean teardown/setup on switch

### 4. Gemini Live Service
- Manages the WebSocket connection to Gemini's multimodal live API
- Handles session creation, configuration updates, and reconnection
- Multiplexes vision frames + audio into the stream
- Parses responses: audio chunks, text transcripts, and tool calls
- Tool calls are routed to OpenClaw or handled locally

### 5. OpenClaw Bridge
- HTTP client connecting to the OpenClaw Gateway on the local network
- Discovers gateway via mDNS/Bonjour (`.local` hostname)
- Translates Gemini tool calls into OpenClaw skill invocations
- Returns results back to Gemini for conversational integration

## Key Use Cases

### Mode 1: Assistant (Default)
- General-purpose AI assistant with eyes and ears
- "What am I looking at?" — scene description
- "Read that sign" — OCR and interpretation
- "Remember this" — save visual context to memory
- System instruction: helpful assistant with vision and tool access

### Mode 2: Translator
- Real-time Mandarin ↔ English translation
- Hears speech in one language, responds in the other
- Visual translation: point at text, get translation overlaid
- System instruction: you are a translator, always translate between Mandarin and English
- Future: support additional language pairs

### Mode 3: QR Scanner
- Continuous QR code detection from camera frames
- On detection: parse URL/data, present action options
- Actions: open link, add contact, connect WiFi, trigger OpenClaw skill
- Uses Vision framework's VNDetectBarcodesRequest
- System instruction: minimal — QR mode is mostly local processing

### Mode 4: Spotter
- "Spot check" mode for specific visual tasks
- Configure what to watch for: specific objects, people, text, events
- Alert when spotted: "I see a parking spot on your left"
- Runs continuous frame analysis with a focused prompt
- System instruction: watch for [configured items], alert immediately when seen

### Mode 5: Navigator
- Contextual navigation assistance
- "Where's the nearest coffee shop?" → OpenClaw web search + directions
- "What bus is that?" → read bus number from camera, look up route
- Combines vision (reading signs, numbers) with OpenClaw (search, maps)
- Future: AR overlay directions

### Mode 6: Custom
- User-defined modes via custom system instructions
- Configure via Settings: name, system instruction, tools enabled
- Share mode configs as JSON
- Power user feature for specific workflows

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Language | Swift | Native iOS, best performance for real-time AV |
| Min iOS | 17.0 | Required for modern SwiftUI, Vision APIs |
| Architecture | MVVM | Clean separation, SwiftUI-friendly |
| Gemini API | Multimodal Live API | Real-time streaming, vision + audio + tools |
| Audio format | 16kHz mono PCM | Gemini's preferred input format |
| Frame format | JPEG, 80% quality | Good balance of size vs quality for vision |
| Frame rate | 1 fps to Gemini | Cost/latency balance; configurable |
| Networking | URLSession WebSocket | Native, no dependencies for WS |
| OpenClaw | HTTP REST | Simple, reliable, LAN-only |
| QR Detection | Vision framework | Native, fast, no dependencies |
| Config | UserDefaults + JSON | Simple persistence, exportable configs |

## Project Structure

```
OpenGlass/
├── App/
│   ├── OpenGlassApp.swift          # App entry point
│   └── ContentView.swift           # Root view with mode routing
├── Config/
│   └── OpenGlassConfig.swift       # Configuration management
├── Gemini/
│   ├── GeminiLiveService.swift     # WebSocket connection manager
│   ├── GeminiSessionViewModel.swift # Session state & UI binding
│   └── AudioManager.swift          # Audio capture & playback
├── Vision/
│   ├── GlassesCameraManager.swift  # Meta Ray-Ban DAT SDK integration
│   ├── IPhoneCameraManager.swift   # Fallback iPhone camera
│   ├── FrameThrottler.swift        # Frame rate limiting
│   └── QRDetector.swift            # QR/barcode detection
├── Modes/
│   ├── ModeProtocol.swift          # Mode interface definition
│   ├── ModeRouter.swift            # Mode state machine
│   ├── AssistantMode.swift         # General assistant mode
│   ├── TranslatorMode.swift        # Translation mode
│   ├── QRScannerMode.swift         # QR scanning mode
│   └── SpotterMode.swift           # Visual spotter mode
├── OpenClaw/
│   ├── OpenClawBridge.swift        # Gateway HTTP client
│   ├── ToolCallRouter.swift        # Tool call dispatch
│   └── ToolCallModels.swift        # Tool call data models
├── UI/
│   ├── GlassesConnectionView.swift # Glasses pairing UI
│   ├── ModePickerView.swift        # Mode selection UI
│   ├── TranscriptView.swift        # Live transcript display
│   └── SettingsView.swift          # App settings
├── docs/
│   ├── MODES.md                    # Mode system documentation
│   └── SETUP.md                    # Setup guide
├── SPEC.md                         # This file
├── README.md                       # Project overview
├── LICENSE                         # MIT License
└── CONTRIBUTING.md                 # Contribution guide
```

## Build Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Xcode project setup with SwiftUI
- [ ] Basic app shell with tab navigation
- [ ] iPhone camera capture (fallback mode)
- [ ] Frame throttling and JPEG encoding
- [ ] Audio capture via AVAudioEngine

### Phase 2: Gemini Integration (Week 3-4)
- [ ] Gemini Live WebSocket connection
- [ ] Audio streaming (send mic, receive responses)
- [ ] Vision frame streaming
- [ ] Basic tool call handling
- [ ] Session management (connect, disconnect, reconnect)

### Phase 3: OpenClaw Bridge (Week 5)
- [ ] Gateway discovery via mDNS
- [ ] HTTP client for skill invocation
- [ ] Tool call routing (Gemini → OpenClaw)
- [ ] Result integration back to Gemini

### Phase 4: Mode System (Week 6-7)
- [ ] Mode protocol and router
- [ ] Assistant mode (default)
- [ ] Translator mode
- [ ] QR Scanner mode
- [ ] Spotter mode
- [ ] Mode switching via voice and UI

### Phase 5: Polish & Glasses (Week 8-10)
- [ ] Meta Ray-Ban DAT SDK integration
- [ ] Glasses connection UI
- [ ] Audio routing (glasses speaker)
- [ ] Settings and configuration
- [ ] Error handling and reconnection
- [ ] Performance optimization

### Phase 6: Advanced Features (Ongoing)
- [ ] Navigator mode
- [ ] Custom mode builder
- [ ] Conversation history / memory
- [ ] Widget for quick mode switching
- [ ] Shortcuts integration

## Future Ideas

- **AR Overlay**: When Apple supports it, overlay translations/annotations in the glasses view
- **Multi-language Translation**: Extend beyond Mandarin ↔ English
- **Offline Mode**: On-device models for basic functionality without internet
- **Wearable Integration**: Apple Watch companion for quick mode switching
- **Social Features**: Share what you're seeing with friends via OpenClaw messaging
- **Developer SDK**: Let others build OpenGlass modes as plugins
- **Recording**: Save interesting moments with AI-generated summaries
- **Accessibility**: Describe scenes for visually impaired users (ironic with glasses, but useful for camera-only mode)

## Hardware Requirements

- **iPhone**: iOS 17.0+, iPhone 12 or later recommended
- **Smart Glasses**: Meta Ray-Ban (2024+) with DAT SDK support
- **Network**: Wi-Fi for OpenClaw Gateway access; cellular for Gemini API
- **OpenClaw**: Mac running OpenClaw Gateway on the same LAN

## References

- [VisionClaw](https://github.com/sseanliu/VisionClaw) — Sean Liu's Gemini Live + OpenClaw glasses project
- [Gemini Multimodal Live API](https://ai.google.dev/gemini-api/docs/multimodal-live) — Google's real-time multimodal API
- [OpenClaw](https://openclaw.app) — AI agent gateway with 56+ skills
- [Meta DAT SDK](https://developers.meta.com/horizon/documentation/dat/dat-overview) — Direct Audio Transfer SDK for Ray-Ban Meta glasses
- [Vision Framework](https://developer.apple.com/documentation/vision) — Apple's computer vision framework

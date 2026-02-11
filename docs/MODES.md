# OpenGlass Mode System 🕶️

## Overview

OpenGlass uses a **mode system** to support different use cases through the same hardware and AI pipeline. Each mode customises the AI's behaviour by providing a unique system instruction, tool set, and optional UI overlay.

Only one mode is active at a time. Switching modes cleanly deactivates the current mode and activates the new one, updating the Gemini session configuration in real-time.

## The Mode Protocol

Every mode conforms to `OpenGlassMode`:

```swift
protocol OpenGlassMode {
    var id: String { get }
    var displayName: String { get }
    var systemInstruction: String { get }
    var enabledTools: [String] { get }

    func activate()
    func deactivate()
}
```

| Property | Purpose |
|----------|---------|
| `id` | Unique identifier for the mode |
| `displayName` | Human-readable name shown in the UI |
| `systemInstruction` | The system prompt sent to Gemini when this mode is active |
| `enabledTools` | Which tools Gemini can call in this mode (`["*"]` = all) |
| `activate()` | Called when the mode becomes active — start any mode-specific services |
| `deactivate()` | Called when switching away — clean up resources |

## Built-in Modes

### 🤖 Assistant (Default)

The general-purpose mode. Gemini has full vision and tool access.

- **Use cases**: Scene description, OCR, memory, general questions
- **Tools**: All enabled
- **System instruction**: Helpful assistant with vision and tools

### 🌐 Translator

Real-time Mandarin ↔ English translation.

- **Use cases**: Spoken translation, visual text translation
- **Tools**: None (pure Gemini)
- **System instruction**: Translate everything between Mandarin and English

### 📱 QR Scanner

Continuous QR code detection with action routing.

- **Use cases**: Open URLs, add contacts, connect WiFi, trigger skills
- **Tools**: `open_url`, `add_contact`
- **Processing**: Primarily local via Vision framework; Gemini assists with interpretation
- **Special**: Activates `QRDetector` on the vision pipeline

### 👁️ Spotter

Configurable visual monitoring.

- **Use cases**: Watch for parking spots, specific people, objects, text
- **Tools**: None
- **System instruction**: Dynamic — includes the configured watch targets
- **Configuration**: Set targets via Settings

### 🏋️ Coach

Real-time visual coaching for physical activities.

- **Use cases**: Gym form correction, cooking guidance, navigation cues, DIY/sports technique
- **Tools**: `execute` (for looking up exercises, recipes, etc.)
- **System instruction**: Short, actionable coaching cues — whispered, not lectured
- **Activation**: "coach mode", "coach me", "watch my form", "help me cook"

### 🤝 Social

Discreet social context assistant — like a friend whispering in your ear.

- **Use cases**: Read name badges, spot company logos, identify event context, read visible text
- **Tools**: `execute` (for looking up companies, people via OpenClaw)
- **System instruction**: Brief, natural observations about social context from visible clues only
- **Activation**: "social mode", "who is this", "who's that"
- **Future**: Will integrate with a personal CRM/contacts database to identify known people and surface relevant history

### 🧭 Navigator (Future)

Contextual navigation assistance.

- **Use cases**: Find places, read bus numbers, get directions
- **Tools**: Web search, maps
- **System instruction**: Navigation-focused with location awareness

### ⚙️ Custom

User-defined modes with configurable system instructions.

- **Use cases**: Anything — specialised workflows, domain-specific assistants
- **Configuration**: Name, system instruction, tool selection — all via Settings
- **Export**: Share as JSON

## Adding a New Mode

1. Create a new Swift file in `OpenGlass/Modes/`
2. Define a struct conforming to `OpenGlassMode`
3. Implement all required properties and lifecycle methods
4. Register the mode in `ModeRouter` (in its initialiser or via `registerMode()`)

### Example

```swift
// OpenGlass - ChefMode.swift

import Foundation

struct ChefMode: OpenGlassMode {
    let id = "chef"
    let displayName = "Chef"
    let systemInstruction = "You are a cooking assistant. Identify ingredients and suggest recipes based on what you see."
    let enabledTools = ["web_search"]

    func activate() {
        // Start any chef-specific services
    }

    func deactivate() {
        // Clean up
    }
}
```

## Mode Switching

Modes can be switched in two ways:

1. **UI**: Tap the mode picker and select a mode
2. **Voice**: Say "switch to translator mode" — Gemini recognises this as a tool call and the `ToolCallRouter` triggers the mode switch locally

On switch, the `ModeRouter`:
1. Calls `deactivate()` on the current mode
2. Updates the active mode reference
3. Calls `activate()` on the new mode
4. Sends a session update to Gemini with the new system instruction and tools

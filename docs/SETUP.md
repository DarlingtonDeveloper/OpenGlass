# OpenGlass Setup Guide 🕶️

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Mac** | macOS 14+ with Xcode 15+ |
| **iPhone** | iOS 17.0+, iPhone 12 or later recommended |
| **Gemini API Key** | From [Google AI Studio](https://aistudio.google.com/apikey) |
| **OpenClaw** | Gateway running on a Mac on the same LAN |
| **Meta Ray-Ban** | Optional — iPhone camera works as fallback |

## Step 1: Get a Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/apikey)
2. Create or select a project
3. Generate an API key
4. Keep it safe — you'll enter it in the app

> **Note**: The Multimodal Live API requires a Gemini model that supports real-time streaming (e.g., `gemini-2.0-flash-live`). Check [the docs](https://ai.google.dev/gemini-api/docs/multimodal-live) for current model availability.

## Step 2: Set Up OpenClaw

OpenClaw Gateway needs to be running on a Mac on the same Wi-Fi network as your iPhone.

```bash
# Check if OpenClaw is running
openclaw gateway status

# Start it if needed
openclaw gateway start
```

The gateway runs at `http://<your-mac>.local:18789` by default. Note your Mac's hostname — you'll need it for the app configuration.

Find your hostname:
```bash
hostname
# e.g., mikes-macbook.local
```

## Step 3: Build the App

```bash
git clone https://github.com/DarlingtonDeveloper/OpenGlass.git
cd OpenGlass
open OpenGlass.xcodeproj
```

In Xcode:
1. Select your iPhone as the build target
2. Set your development team in Signing & Capabilities
3. Build and run (⌘R)

## Step 4: Configure the App

On first launch:

1. **Settings → Gemini**: Enter your API key
2. **Settings → OpenClaw**: Enter your Mac's gateway URL (e.g., `http://mikes-macbook.local:18789`)
3. **Grant permissions**: Camera and microphone access when prompted

## Step 5: Connect Glasses (Optional)

If you have Meta Ray-Ban glasses:

1. Ensure glasses are paired with your iPhone via the Meta View app
2. In OpenGlass, go to the Glasses Connection screen
3. The app will detect the glasses via the DAT SDK
4. Once connected, video and audio will route through the glasses

Without glasses, the app uses the iPhone's rear camera and microphone.

## Step 6: Start Using It

1. Tap **Connect** to start a Gemini Live session
2. The default mode is **Assistant** — just talk naturally
3. Switch modes via the mode picker or say "switch to translator mode"
4. View the live transcript on screen

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Can't connect to Gemini | Check API key, check internet connection |
| Can't reach OpenClaw | Ensure gateway is running, same Wi-Fi network, check URL |
| No camera feed | Grant camera permission in Settings → OpenGlass |
| No audio | Grant microphone permission, check audio route |
| Glasses not detected | Ensure paired in Meta View app, Bluetooth enabled |

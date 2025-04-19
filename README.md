# Mic Stream

**Mic Stream** is a cross-platform solution to stream live microphone audio from an Android phone to a Windows desktop application. The project consists of two components:

- **MicStreamer (Android App)**: Streams real-time mic data.
- **MicReceiver (WPF Desktop App)**: Receives and plays the stream using a selectable output device (e.g., VB-Cable).

---

## Features

### Android App

- Stream mic input over TCP
- Clean and simple UI
- Reconnection logic for dropped connections

### Windows WPF App

- List and select output audio devices
- Playback mic stream in real-time
- Support for virtual output devices (like VB-Cable)

---

## Setup

### Prerequisites

- **Android**: Device running Android 8.0 or higher
- **Windows**: .NET Framework 4.7.2 or higher
- **Virtual Audio Device (optional)**: [VB-Cable](https://www.vb-audio.com/Cable/)

### Running the App

1. **Install VB-Cable** (optional) on your PC to route the stream to a virtual mic.
2. **Launch MicReceiver** on the PC.
   - Choose the desired output device.
   - Click “Start Server.”
3. **Open Mic Stream** on your Android phone.
   - Enter the IP address of your PC and the port (default: `8080`).
   - Tap “Start Streaming.”

---

## Contributing

PRs welcome. Please open issues for suggestions or bugs.

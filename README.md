# SmartEar - Hearing Aid for iPhone

An iPhone application that functions as a hearing aid by capturing ambient sound through the microphone and delivering it to the user via the device's speakers or headphones.

## Features

- ✅ Capture ambient sound and play it back in real time
- ✅ Adjustable amplification (0x – 2x)
- ✅ Live volume indicator in dB
- ✅ Source selection: auto, iPhone mic, headset/Bluetooth mic
- ✅ Simple, accessible UI
- ✅ Error handling and permission requests

## Requirements

- iOS 13.0 or higher
- Xcode 12.0 or higher
- Swift 5.0 or higher
- iPhone with a microphone

## Installation

### Configuring Capabilities

1. In Xcode select the project target.
2. Signing & Capabilities → add **Audio, AirPlay, and Picture in Picture**.
3. Ensure the `NSMicrophoneUsageDescription` string is present (already set).

## Usage

1. Launch the app on your iPhone.
2. Grant microphone access on first launch.
3. Select the mic source (Auto / iPhone / Headset). If the chosen device is unavailable, the app will prompt to change.
4. Press **“Начать прослушивание”**. The live dB indicator shows current level.
5. Use the slider to adjust amplification (0x–2x).
6. Press **“Остановить”** to stop listening.

## Architecture

### Main Components

- **AppDelegate**: Prepares the audio session at launch.
- **SceneDelegate**: Scene lifecycle management.
- **ViewController**: UI, permissions, mic selection, level rendering.
- **AudioEngineManager**: Audio graph, amplification, input selection, interruptions, level meter.

### Technologies

- **AVAudioEngine**: For real-time audio capture and playback
- **AVAudioSession**: For managing audio sessions
- **UIKit**: For the user interface

## Best Practices

The app follows iOS development best practices:

1. **Separation of concerns**: UI vs audio engine.
2. **Permissions**: Explicit microphone request; user-friendly messaging.
3. **Session management**: `AVAudioSession` configured for play/record, Bluetooth/speaker options.
4. **Resource management**: Engine stop/reset, session deactivation on stop, interruption handling.
5. **Safety/UX**: Amplification capped at 2x; live dB feedback; main-thread UI updates.
6. **Accessibility**: Dynamic type-friendly fonts; clear states.

## Potential Improvements

- Adding filters to enhance sound quality
- Adjustable frequency characteristics
- Saving user preferences
- Support for different listening modes
- Sound visualization
- Support for AirPods and other Bluetooth devices

## License

This project is created for educational purposes.

## Notes

⚠️ **Important**: This application is intended to assist with hearing ambient sounds. For medical purposes, please consult a doctor.

⚠️ **Safety**: When using headphones, be cautious with volume levels to avoid hearing damage.

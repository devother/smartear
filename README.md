# SmartEar - Hearing Aid for iPhone

An iPhone application that functions as a hearing aid by capturing ambient sound through the microphone and delivering it to the user via the device's speakers or headphones.

## Features

- ✅ Capture sound via the iPhone's microphone
- ✅ Real-time sound delivery through speakers or headphones
- ✅ Adjustable sound amplification (0x - 2x)
- ✅ Simple and intuitive interface
- ✅ Bluetooth headphone support
- ✅ Error handling and permission requests

## Requirements

- iOS 13.0 or higher
- Xcode 12.0 or higher
- Swift 5.0 or higher
- iPhone with a microphone

## Installation

### Creating a Project in Xcode

1. Open Xcode
2. Create a new project: **File → New → Project**
3. Select **iOS → App**
4. Fill in project details:
   - Product Name: `SmartEar`
   - Team: Select your team
   - Organization Identifier: e.g., `com.yourcompany`
   - Interface: **Storyboard** or **SwiftUI** (we are using code)
   - Language: **Swift**
5. Save the project

### Adding Files

1. Copy all files from this directory into your project folder in Xcode:
   - `AppDelegate.swift`
   - `SceneDelegate.swift`
   - `ViewController.swift`
   - `AudioEngineManager.swift`
   - `Info.plist` (replace the existing one)

2. In Xcode:
   - Delete the existing `Info.plist` from the project
   - Add the new `Info.plist` via **File → Add Files to "SmartEar"**
   - Ensure all `.swift` files are added to the Target

### Configuring Info.plist

Ensure the following keys are present in `Info.plist`:

- `NSMicrophoneUsageDescription` - description for microphone access request
- `UIBackgroundModes` with `audio` - for background operation (optional)

### Configuring Capabilities

1. In Xcode, select the project in the navigator
2. Go to the **Signing & Capabilities** tab
3. Ensure the following are enabled:
   - **Audio, AirPlay, and Picture in Picture** (for audio functionality)

## Usage

1. Launch the app on your iPhone
2. Grant microphone access permission on first launch
3. Press the **"Start Listening"** button
4. Use the slider to adjust sound amplification
5. To stop, press the **"Stop Listening"** button

## Architecture

### Main Components

- **AppDelegate**: Configures the audio session on app launch
- **SceneDelegate**: Manages the scene lifecycle
- **ViewController**: Main screen with UI and control
- **AudioEngineManager**: Handles audio processing via AVAudioEngine

### Technologies

- **AVAudioEngine**: For real-time audio capture and playback
- **AVAudioSession**: For managing audio sessions
- **UIKit**: For the user interface

## Best Practices

The app follows iOS development best practices:

1. **Separation of Concerns**: Audio logic is separated from UI
2. **Error Handling**: All errors are handled and displayed to the user
3. **Permission Requests**: Proper handling of microphone access permissions
4. **Resource Management**: Correct release of resources upon stopping
5. **UI/UX**: Intuitive interface with feedback
6. **Thread Safety**: All UI updates are performed on the main thread

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
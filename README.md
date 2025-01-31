# SnapArt

SnapArt is an iOS application that transforms your photos into various artistic styles using AI-powered image generation. The app combines the power of Stability AI's image processing capabilities with an intuitive user interface to create unique artistic renditions of your photos.

## Features

- **Camera Integration**: Take photos directly within the app or choose from your photo library
- **8 Artistic Styles**:
  - 🌆 Cyberpunk Neon: Dark cyberpunk aesthetic with vibrant neon lights
  - 📷 Vintage Sepia: Warm, vintage tone reminiscent of old photographs
  - 🎨 Whimsical Watercolor: Soft, pastel colors with gentle brush strokes
  - 🎯 Bold Pop Art: Flat, saturated colors with comic-book aesthetic
  - ⚙️ Steampunk Victorian: Mechanical gears and brass tones
  - 🔲 Minimalist Flat: Clean shapes and subdued color palette
  - 🖼️ Baroque Painting: Rich shadows and classical detailing
  - 📐 Abstract Cubist: Geometric shapes and fragmented perspectives

## Technical Details

- **Platform**: iOS 17+
- **Framework**: SwiftUI
- **APIs**: 
  - Stability AI for image transformation
  - AVFoundation for camera handling
  - PhotoKit for photo library access

## Setup Instructions

1. Clone the repository
2. Set up API keys:
   - Copy `Config.template.xcconfig` to `Config.xcconfig`
   - Get your API key from [Stability AI](https://platform.stability.ai/)
   - Replace the placeholder in `Config.xcconfig` with your actual API key
3. Build and run in Xcode

⚠️ **Important**: Never commit your `Config.xcconfig` file to version control. It's already added to `.gitignore` to prevent accidental commits.

## Security Considerations

- API keys are stored locally in `Config.xcconfig` and UserDefaults
- The app uses secure HTTPS connections for all API calls
- Camera and photo library permissions are requested at runtime
- No user data is stored on remote servers
- All image processing is done through Stability AI's secure API

## Privacy

The app requires:
- Camera access for taking photos
- Photo library access for saving processed images
- Internet access for API communication

No data is collected or shared beyond what's necessary for image processing.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

Please ensure you don't commit any API keys or sensitive information.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Developed by GarryGao00
Using Stability AI's image generation technology
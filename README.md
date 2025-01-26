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

## Architecture

The app follows a clean architecture pattern with:
- **Views**: SwiftUI views for user interface
- **ViewModels**: Business logic and state management
- **Services**: API integration and image processing
- **Configuration**: Secure API key management

## Setup

1. Clone the repository
2. Add your Stability AI API key to `Config.xcconfig`
3. Build and run in Xcode

## Configuration

The app requires a Stability AI API key. 

## Privacy

The app requires camera and photo library permissions for basic functionality. These permissions are requested at runtime and can be managed in the device's Settings app.

## Credits

Developed by GarryGao00
Using Stability AI's image generation technology
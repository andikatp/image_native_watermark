# image_native_watermark

[![pub package](https://img.shields.io/pub/v/image_native_watermark.svg)](https://pub.dev/packages/image_native_watermark)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-flutter%20%7C%20android%20%7C%20ios-blue.svg)](https://pub.dev/packages/image_native_watermark)

A high-performance Flutter plugin for native camera frame processing and image file watermarking (rotation, scaling, text overlay, and JPEG compression) on Android and iOS.

## Features

- **⚡ High Performance Native Processing**: Executes the full image pipeline natively (Android Kotlin/Bitmap & iOS Swift/CoreGraphics) bypassing Dart thread overhead and Shorebird interpreter slowdowns.
- **📷 Camera Frame Processing**: Converts raw camera stream bytes (`NV21` / `BGRA8888`) directly into watermarked compressed JPEG images.
- **🖼️ Image File Watermarking**: Watermark existing image files (e.g. from `image_picker` or file system) via `ImageNativeWatermark.processImagePath`.
- **📱 Orientation & Mirroring**: Supports hardware rotation angle alignment and front camera horizontal mirroring.
- **📐 Dynamic Scaling & Compression**: Custom target max width resizing and JPEG quality compression.
- **✍️ Text Overlay**: Overlay custom text watermark timestamp or custom metadata directly onto the image.

## Installation

Add `image_native_watermark` to your `pubspec.yaml`:

```yaml
dependencies:
  image_native_watermark: 0.0.2
```

Or run:

```bash
flutter pub add image_native_watermark
```

## Usage

### 1. Watermark Image File (e.g., ImagePicker)

```dart
import 'package:image_native_watermark/image_native_watermark.dart';

Future<String?> watermarkPickedImage(String inputPath, String outputPath) async {
  final String? result = await ImageNativeWatermark.processImagePath(
    imagePath: inputPath,
    watermarkText: "Location: -6.200000, 106.816666\nDate: 2026-07-23 11:00:00",
    outputPath: outputPath,
    quality: 85,
    targetMaxWidth: 1080,
  );

  return result;
}
```

### 2. Stream Frame Handling (Raw Camera Stream)

```dart
import 'package:flutter/services.dart';
import 'package:image_native_watermark/image_native_watermark.dart';

Future<String?> processCameraFrame(Uint8List frameBytes, int width, int height) async {
  final String? outputPath = await ImageNativeWatermark.processFrame(
    bytes: frameBytes,
    width: width,
    height: height,
    bytesPerRow: width * 4,
    rotationAngle: 90,
    isFrontCamera: true,
    watermarkText: "Location: -6.200000, 106.816666\nDate: 2026-07-23 11:00:00",
    quality: 85,
    targetMaxWidth: 1080,
    outputPath: "/path/to/output.jpg",
  );

  return outputPath;
}
```

## Author

**Andika Tri Prasetya**

- Email: triprasetya_andika@yahoo.com
- GitHub: [github.com/andikatp](https://github.com/andikatp)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

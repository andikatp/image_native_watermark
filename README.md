# image_native_watermark

A high-performance Flutter plugin for native camera frame processing, rotation, scaling, text watermarking, and JPEG compression on Android and iOS.

## Features

- **⚡ High Performance Native Processing**: Executes the full image pipeline natively (Android Kotlin/Bitmap & iOS Swift/CoreGraphics) bypassing Dart thread overhead and Shorebird interpreter slowdowns.
- **🔄 Stream Frame Handling**: Converts raw camera stream bytes (`NV21` / `BGRA8888`) directly into watermarked compressed JPEG images.
- **📱 Orientation & Mirroring**: Supports hardware rotation angle alignment and front camera horizontal mirroring.
- **📐 Dynamic Scaling & Compression**: Custom target max width resizing and JPEG quality compression.
- **✍️ Text Overlay**: Overlay custom text watermark timestamp or custom metadata directly onto the frame.

## Installation

Add `image_native_watermark` to your `pubspec.yaml`:

```yaml
dependencies:
  image_native_watermark: ^0.0.1
```

Or run:

```bash
flutter pub add image_native_watermark
```

## Usage

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

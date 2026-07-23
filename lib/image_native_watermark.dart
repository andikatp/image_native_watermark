import 'package:flutter/services.dart';

class ImageNativeWatermark {
  static const MethodChannel _channel = MethodChannel('image_native_watermark');

  /// Converts raw camera bytes into a watermarked, compressed JPEG file.
  /// 
  /// Handles the full pipeline natively: NV21/BGRA → rotate → flip → resize →
  /// watermark → JPEG encode — making it immune to Shorebird interpreter slowdowns.
  /// 
  /// Returns the path to the output JPEG file.
  static Future<String?> processFrame({
    required Uint8List bytes,
    required int width,
    required int height,
    required int bytesPerRow,
    required int rotationAngle,
    required bool isFrontCamera,
    required String watermarkText,
    required int quality,
    required int targetMaxWidth,
    required String outputPath,
  }) async {
    final result = await _channel.invokeMethod<String>('processFrame', {
      'bytes': bytes,
      'width': width,
      'height': height,
      'bytesPerRow': bytesPerRow,
      'rotationAngle': rotationAngle,
      'isFrontCamera': isFrontCamera,
      'watermarkText': watermarkText,
      'quality': quality,
      'targetMaxWidth': targetMaxWidth,
      'outputPath': outputPath,
    });
    return result;
  }
}

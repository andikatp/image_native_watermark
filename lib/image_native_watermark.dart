/// High-performance native image processing and watermarking for Flutter.
library;

import 'dart:io';
import 'package:flutter/services.dart';

/// A native image processing and watermarking utility.
class ImageNativeWatermark {
  /// Private constructor to prevent instantiation.
  const ImageNativeWatermark._();

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

  /// Adds a watermark and resizes/compresses an existing image file (e.g. from ImagePicker).
  ///
  /// Reads the image from [imagePath] (or [imageBytes]), applies [watermarkText]
  /// with optional [targetMaxWidth] and [quality] compression natively, and saves
  /// the output to [outputPath].
  static Future<String?> processImagePath({
    required String imagePath,
    required String watermarkText,
    required String outputPath,
    int quality = 85,
    int targetMaxWidth = 1080,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();

    final result = await _channel.invokeMethod<String>('processImageFile', {
      'bytes': bytes,
      'watermarkText': watermarkText,
      'quality': quality,
      'targetMaxWidth': targetMaxWidth,
      'outputPath': outputPath,
    });
    return result;
  }
}

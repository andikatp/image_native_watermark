import 'package:flutter/material.dart';
import 'package:image_native_watermark/image_native_watermark.dart';

void main() {
  runApp(const MyApp());
}

/// Example app demonstrating [ImageNativeWatermark].
class MyApp extends StatelessWidget {
  /// Creates the example app root widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Image Native Watermark Example')),
        body: const Center(
          child: Text('Image Native Watermark Example'),
        ),
      ),
    );
  }
}

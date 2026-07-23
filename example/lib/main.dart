import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_native_watermark/image_native_watermark.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
      title: 'Image Native Watermark Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const WatermarkDemoScreen(),
    );
  }
}

/// Main interactive screen for picking and watermarking images.
class WatermarkDemoScreen extends StatefulWidget {
  /// Creates the watermark demo screen.
  const WatermarkDemoScreen({super.key});

  @override
  State<WatermarkDemoScreen> createState() => _WatermarkDemoScreenState();
}

class _WatermarkDemoScreenState extends State<WatermarkDemoScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _originalImage;
  File? _watermarkedImage;
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _pickAndProcessImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final originalFile = File(pickedFile.path);
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'watermarked_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final timestamp = DateTime.now().toIso8601String().split('.').first;
      const sampleLocation = 'Lat: -6.200000, Lng: 106.816666';
      final watermarkText = 'Location: $sampleLocation\nDate: $timestamp';

      final resultPath = await ImageNativeWatermark.processImagePath(
        imagePath: originalFile.path,
        watermarkText: watermarkText,
        outputPath: outputPath,
        quality: 85,
        targetMaxWidth: 1080,
      );

      if (resultPath != null) {
        setState(() {
          _originalImage = originalFile;
          _watermarkedImage = File(resultPath);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to process image watermark.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Native Watermark'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcessImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _pickAndProcessImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessing) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_watermarkedImage != null) ...[
              Text(
                'Watermarked Output:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _watermarkedImage!,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_originalImage != null) ...[
              Text(
                'Original Image:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _originalImage!,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

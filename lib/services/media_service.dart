// lib/services/media_service.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MediaService {
  CameraController? _frontCamera;
  CameraController? _backCamera;
  List<String> capturedMedia = [];
  String? _mediaDirectory;
  Timer? _captureTimer;

  Future<void> initialize() async {
    // Create media directory
    final appDir = await getApplicationDocumentsDirectory();
    _mediaDirectory = path.join(appDir.path, 'emergency_media');
    final directory = Directory(_mediaDirectory!);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    // Initialize cameras
    final cameras = await availableCameras();
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        _frontCamera = CameraController(camera, ResolutionPreset.medium);
        await _frontCamera?.initialize();
      } else if (camera.lensDirection == CameraLensDirection.back) {
        _backCamera = CameraController(camera, ResolutionPreset.medium);
        await _backCamera?.initialize();
      }
    }
  }

  Future<String?> captureImage(CameraController? camera, String prefix) async {
    if (camera == null || !camera.value.isInitialized) return null;

    try {
      final XFile photo = await camera.takePicture();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath =
          path.join(_mediaDirectory!, '${prefix}_$timestamp.jpg');

      // Copy file to our app directory
      await File(photo.path).copy(filePath);
      return filePath;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  Future<List<String>> startCapturing() async {
    capturedMedia.clear();

    for (int i = 0; i < 5; i++) {
      // Capture 5 sets of images
      if (_frontCamera != null) {
        final frontPath = await captureImage(_frontCamera, 'front');
        if (frontPath != null) capturedMedia.add(frontPath);
      }

      if (_backCamera != null) {
        final backPath = await captureImage(_backCamera, 'back');
        if (backPath != null) capturedMedia.add(backPath);
      }

      await Future.delayed(Duration(seconds: 2));
    }

    return capturedMedia;
  }

  void dispose() {
    _frontCamera?.dispose();
    _backCamera?.dispose();
    _captureTimer?.cancel();
  }
}

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class IntruderSelfieService {
  static int _failedAttempts = 0;
  static const int _maxAttempts = 3;
  static CameraController? _cameraController;

  static Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
  }

  static Future<void> onUnlockAttempt(bool successful) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('intruder_selfie_enabled') ?? false;

    if (!isEnabled) return;

    if (successful) {
      _failedAttempts = 0;
      return;
    }

    _failedAttempts++;

    if (_failedAttempts >= _maxAttempts) {
      await _capturePhoto();
      _failedAttempts = 0;
    }
  }

  static Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await initialize();
    }

    try {
      final image = await _cameraController!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final filename = 'intruder_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File(path.join(directory.path, filename));
      await File(image.path).copy(savedImage.path);

      final prefs = await SharedPreferences.getInstance();
      final photos = prefs.getStringList('intruder_photos') ?? [];
      photos.add(savedImage.path);
      await prefs.setStringList('intruder_photos', photos);
    } catch (e) {
      print('Error capturing intruder photo: $e');
    }
  }

  static void dispose() {
    _cameraController?.dispose();
    _cameraController = null;
  }
}

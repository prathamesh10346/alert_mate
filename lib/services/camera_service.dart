// lib/services/camera_service.dart
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class CameraService {
  CameraController? _frontController;
  CameraController? _backController;
  bool _isInitialized = false;
  Timer? _captureTimer;
  List<String> _capturedPhotos = [];
 

  Future<List<String>> startPeriodicCapture() async {
    if (!_isInitialized) await initialize();
    _capturedPhotos.clear();

    final directory = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${directory.path}/emergency_photos');
    if (!photoDir.existsSync()) {
      await photoDir.create(recursive: true);
    }

    int captureCount = 0;
    final completer = Completer<List<String>>();

    _captureTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // Create separate futures for front and back camera captures
        Future<void>? frontCapture;
        Future<void>? backCapture;

        // Setup front camera capture
        if (_frontController != null && _frontController!.value.isInitialized) {
          frontCapture =
              _frontController!.takePicture().then((frontImage) async {
            final frontPath = '${photoDir.path}/front_$timestamp.jpg';
            await frontImage.saveTo(frontPath);
            _capturedPhotos.add(frontPath);
            print('Front photo captured: $frontPath');
          }).catchError((e) {
            print('Error capturing front photo: $e');
          });
        }

        // Setup back camera capture
        if (_backController != null && _backController!.value.isInitialized) {
          // Add a small delay to prevent camera resource conflicts
          await Future.delayed(Duration(milliseconds: 100));
          backCapture = _backController!.takePicture().then((backImage) async {
            final backPath = '${photoDir.path}/back_$timestamp.jpg';
            await backImage.saveTo(backPath);
            _capturedPhotos.add(backPath);
            print('Back photo captured: $backPath');
          }).catchError((e) {
            print('Error capturing back photo: $e');
          });
        }

        // Wait for both captures to complete
        await Future.wait([
          if (frontCapture != null) frontCapture,
          if (backCapture != null) backCapture,
        ]);

        captureCount++;
        print('Captured photos set $captureCount of 5');

        if (captureCount >= 5) {
          timer.cancel();
          completer.complete(_capturedPhotos);
        }
      } catch (e) {
        print('Error during periodic capture: $e');
        timer.cancel();
        completer.complete(_capturedPhotos);
      }
    });

    return completer.future;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final cameras = await availableCameras();
      print('Available cameras: ${cameras.length}');

      // Sort cameras to ensure consistent initialization order
      final sortedCameras = cameras
          .where((camera) =>
              camera.lensDirection == CameraLensDirection.back ||
              camera.lensDirection == CameraLensDirection.front)
          .toList()
        ..sort((a, b) => a.lensDirection == CameraLensDirection.back ? -1 : 1);

      for (var camera in sortedCameras) {
        print(
            'Initializing camera: ${camera.lensDirection}, id: ${camera.name}');

        if (camera.lensDirection == CameraLensDirection.back) {
          _backController = CameraController(
            camera,
            ResolutionPreset.medium,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
          await _backController?.initialize();
          print('Back camera initialized successfully');
        } else if (camera.lensDirection == CameraLensDirection.front) {
          _frontController = CameraController(
            camera,
            ResolutionPreset.medium,
            enableAudio: false,
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
          await _frontController?.initialize();
          print('Front camera initialized successfully');
        }
      }

      if (_frontController == null && _backController == null) {
        throw Exception('No cameras available');
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing cameras: $e');
      throw e;
    }
  }

  Future<void> dispose() async {
    _captureTimer?.cancel();
    await _frontController?.dispose();
    await _backController?.dispose();
    _isInitialized = false;
    _capturedPhotos.clear();
  }
}

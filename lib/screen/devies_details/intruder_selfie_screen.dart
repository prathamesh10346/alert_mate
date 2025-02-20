import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class IntruderSelfieScreen extends StatefulWidget {
  @override
  _IntruderSelfieScreenState createState() => _IntruderSelfieScreenState();
}

class _IntruderSelfieScreenState extends State<IntruderSelfieScreen> {
  bool isEnabled = false;
  List<String> capturedPhotos = [];
  static const platform =
      MethodChannel('com.example.alert_mate/intruder_detection');

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkStatus() async {
    try {
      final bool enabled =
          await platform.invokeMethod('isIntruderDetectionEnabled');
      setState(() {
        isEnabled = enabled;
      });
    } catch (e) {
      print('Error checking status: $e');
    }
  }

  void _setupMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onFailedAttempt') {
        await _captureIntruderPhoto();
      }
    });
  }

  Future<void> _toggleFeature(bool value) async {
    try {
      if (value) {
        await platform.invokeMethod('enableIntruderDetection');
      } else {
        await platform.invokeMethod('disableIntruderDetection');
      }
      await _checkStatus();
    } catch (e) {
      print('Error toggling feature: $e');
    }
  }

  Future<void> _captureIntruderPhoto() async {
    try {
      // Add a small delay to ensure camera is ready
      await Future.delayed(Duration(milliseconds: 500));

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      // Add another small delay after initialization
      await Future.delayed(Duration(milliseconds: 500));

      if (!controller.value.isInitialized) {
        throw Exception('Failed to initialize camera');
      }

      final image = await controller.takePicture();

      // Save the image
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'intruder_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${directory.path}/$fileName';

      await File(image.path).copy(filePath);

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      List<String> photos = prefs.getStringList('intruder_photos') ?? [];
      photos.add(filePath);
      await prefs.setStringList('intruder_photos', photos);

      await controller.dispose();
    } catch (e) {
      print('Error capturing photo: $e');
    }
  }

  Future<void> _loadSavedPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      capturedPhotos = prefs.getStringList('intruder_photos') ?? [];
    });
  }

  Future<void> _checkFeatureStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isEnabled = prefs.getBool('intruder_selfie_enabled') ?? false;
    });
  }

  Future<void> _deletePhoto(String photoPath) async {
    final file = File(photoPath);
    if (await file.exists()) {
      await file.delete();
    }

    setState(() {
      capturedPhotos.remove(photoPath);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('intruder_photos', capturedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Intruder Selfie'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text('Enable Intruder Selfie'),
            subtitle: Text(
              'Capture photo after 3 failed unlock attempts',
              style: TextStyle(fontSize: 12),
            ),
            value: isEnabled,
            onChanged: _toggleFeature,
          ),
          Expanded(
            child: capturedPhotos.isEmpty
                ? Center(
                    child: Text('No intruder photos captured yet'),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: capturedPhotos.length,
                    itemBuilder: (context, index) {
                      final photoPath = capturedPhotos[index];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(photoPath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deletePhoto(photoPath),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

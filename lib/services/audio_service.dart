// lib/services/audio_service.dart
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;
  String? _recordingPath;
  String? _mediaDirectory;

  Future<bool> checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    final storageStatus = await Permission.storage.status;

    if (micStatus.isDenied || storageStatus.isDenied) {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.microphone,
        Permission.storage,
      ].request();

      return statuses[Permission.microphone]!.isGranted &&
          statuses[Permission.storage]!.isGranted;
    }

    return micStatus.isGranted && storageStatus.isGranted;
  }

  Future<void> initialize() async {
    try {
      final hasPermissions = await checkPermissions();
      if (!hasPermissions) {
        throw RecordingPermissionException('Required permissions were denied');
      }

      _recorder = FlutterSoundRecorder(logLevel: Level.error);

      final appDir = await getApplicationDocumentsDirectory();
      _mediaDirectory = path.join(appDir.path, 'emergency_media');
      final directory = Directory(_mediaDirectory!);
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      await _recorder!.openRecorder();
      _isRecorderInitialized = true;
    } catch (e) {
      print('Error initializing audio service: $e');
      rethrow;
    }
  }

  Future<void> startRecording() async {
    try {
      if (!_isRecorderInitialized) await initialize();

      if (_recorder?.isRecording ?? false) {
        await stopRecording();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      _recordingPath =
          path.join(_mediaDirectory!, 'emergency_audio_$timestamp.aac');

      await _recorder!.startRecorder(
        toFile: _recordingPath,
        codec: Codec.aacADTS,
      );
    } catch (e) {
      print('Error starting recording: $e');
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      if (!_isRecorderInitialized || !(_recorder?.isRecording ?? false)) {
        return null;
      }

      await _recorder!.stopRecorder();
      return _recordingPath;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    try {
      if (_isRecorderInitialized) {
        await _recorder!.closeRecorder();
        _isRecorderInitialized = false;
      }
    } catch (e) {
      print('Error disposing audio service: $e');
    }
  }
}

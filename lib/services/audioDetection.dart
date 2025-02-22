import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioCrashDetectionService {
  static const double CRASH_THRESHOLD = 0.98;
  static const int SAMPLE_RATE = 44100;
  static const int CHANNELS = 1;
  static const int BITS_PER_SAMPLE = 16;

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  late Interpreter _interpreter;
  late List<String> _labels;
  bool _isRecording = false;
  StreamSubscription? _recordingDataSubscription;
  final Function(double confidence) onCrashDetected;

  AudioCrashDetectionService({required this.onCrashDetected}) {
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    await _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      final modelFile =
          await _getModel('assets/model/soundclassifier_with_metadata.tflite');
      _interpreter = await Interpreter.fromFile(modelFile);
print('Model loaded successfully');
      final labelsData = await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelsData.split('\n');
    } catch (e) {
      print('Model initialization error: $e');
      throw Exception('Failed to initialize model');
    }
  }

  Future<File> _getModel(String assetPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelFile = File('${appDir.path}/sound_classifier_model.tflite');

    if (!await modelFile.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await modelFile.writeAsBytes(byteData.buffer.asUint8List());
    }

    return modelFile;
  }

  Future<void> startMonitoring() async {
    if (!_isRecording) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) return;

      _isRecording = true;
      await _startContinuousRecording();
    }
  }

  Future<void> _startContinuousRecording() async {
    try {
      await _recorder.startRecorder(
        toStream: 
        null,
        codec: Codec.pcm16WAV,
        numChannels: CHANNELS,
        sampleRate: SAMPLE_RATE,
      );

      _recordingDataSubscription = _recorder.onProgress!.listen((event) async {
        if (event.duration.inSeconds >= 3) {
          // Get the recorded data
          final buffer = await _recorder.stopRecorder();

          // Restart recording
          await _recorder.startRecorder(
            toStream: null,
            codec: Codec.pcm16WAV,
            numChannels: CHANNELS,
            sampleRate: SAMPLE_RATE,
          );

          if (buffer != null) {
            await _processAudioBuffer(buffer as Uint8List);
          }
        }
      });
    } catch (e) {
      print('Recording error: $e');
      _isRecording = false;
    }
  }

  Future<void> _processAudioBuffer(Uint8List buffer) async {
    try {
      // Convert buffer to List<double>
      List<double> audioData = _convertBufferToDoubles(buffer);

      // Preprocess the audio data
      List<double> processedAudio = _preprocessAudioData(audioData);

      // Prepare input tensor
      var inputArray = [processedAudio];
      var outputArray =
          List<double>.filled(_labels.length, 0).reshape([1, _labels.length]);

      // Run inference
      _interpreter.run(inputArray, outputArray);

      // Get crash confidence
      int crashIndex = _labels.indexOf('car_crash');
      if (crashIndex != -1) {
        double crashConfidence = outputArray[0][crashIndex];

        if (crashConfidence >= CRASH_THRESHOLD) {
          onCrashDetected(crashConfidence);
        }
      }
    } catch (e) {
      print('Audio processing error: $e');
    }
  }

  List<double> _convertBufferToDoubles(Uint8List buffer) {
    // Convert 16-bit PCM to doubles
    List<double> samples = [];
    for (int i = 44; i < buffer.length; i += 2) {
      // Skip WAV header (44 bytes)
      int sample = buffer[i] | (buffer[i + 1] << 8);
      if (sample > 32767) sample -= 65536;
      samples.add(sample / 32768.0); // Normalize to [-1.0, 1.0]
    }
    return samples;
  }

  List<double> _preprocessAudioData(List<double> audioData) {
    // Apply preprocessing steps
    final windowSize = 2048;
    final hopSize = windowSize ~/ 2;
    final numFrames = (audioData.length - windowSize) ~/ hopSize + 1;

    // Apply Hamming window
    final window = List<double>.generate(
        windowSize, (i) => 0.54 - 0.46 * cos(2 * pi * i / (windowSize - 1)));

    // Process frames
    List<double> features = [];
    for (int i = 0; i < numFrames; i++) {
      final startIdx = i * hopSize;
      final frame = audioData.sublist(startIdx, startIdx + windowSize);

      // Apply window
      for (int j = 0; j < windowSize; j++) {
        frame[j] *= window[j];
      }

      // Calculate RMS energy
      double rms =
          sqrt(frame.map((x) => x * x).reduce((a, b) => a + b) / windowSize);
      features.add(rms);

      // Add zero crossing rate
      int zeroCrossings = 0;
      for (int j = 1; j < windowSize; j++) {
        if ((frame[j] >= 0 && frame[j - 1] < 0) ||
            (frame[j] < 0 && frame[j - 1] >= 0)) {
          zeroCrossings++;
        }
      }
      features.add(zeroCrossings / windowSize);
    }

    return features;
  }

  Future<void> stopMonitoring() async {
    _isRecording = false;
    _recordingDataSubscription?.cancel();
    if (_recorder.isRecording) {
      await _recorder.stopRecorder();
    }
  }

  Future<void> dispose() async {
    await stopMonitoring();
    _recordingDataSubscription?.cancel();
    await _recorder.closeRecorder();
    await _player.closePlayer();
    _interpreter.close();
  }
}

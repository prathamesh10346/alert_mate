import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class AccidentDetectionService {
  // Thresholds for accident detection
  static const double ACCELERATION_THRESHOLD =40.0; // ~3G force
  static const double SUSTAINED_ACCELERATION_THRESHOLD = 20.0; // ~1.5G force
  static const double ANGULAR_VELOCITY_THRESHOLD = 7.0; // rad/s
  static const double SPEED_THRESHOLD = 20.0; // m/s (~18 km/h minimum speed)
  static const double SUDDEN_SPEED_CHANGE_THRESHOLD = 20.0; // m/s
  static const int ACCELERATION_WINDOW_MS = 300; // 100ms window for impact
  static const int DETECTION_COOLDOWN_MS = 10000; // 30 seconds cooldown

  // Stream controllers
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  StreamSubscription? _locationSubscription;

  // Callback function for accident detection
  final Function(AccidentData) onAccidentDetected;

  // Current sensor values
  double _currentAcceleration = 0.0;
  double _currentAngularVelocity = 0.0;
  Position? _lastPosition;
  DateTime? _lastSpeedCheck;
  double _lastSpeed = 0.0;
  DateTime? _lastAccidentTime;
  bool _isProcessingAccident = false;
  List<double> _recentAccelerations = [];
  List<double> _sustainedAccelerations = [];
  Timer? _accelerationTimer;
  AccidentDetectionService({required this.onAccidentDetected});

  Future<void> startMonitoring(BuildContext context) async {
    // Request necessary permissions
    await _requestPermissions(context);
    _startSensorMonitoring();
    // Start sensor monitoring
    _startAccelerometerMonitoring();
    _startGyroscopeMonitoring();
    _startLocationMonitoring();
  }

  void _processAcceleration(double acceleration) {
    _recentAccelerations.add(acceleration);
    _sustainedAccelerations.add(acceleration);

    // Keep only recent readings
    while (_recentAccelerations.length > 10) {
      _recentAccelerations.removeAt(0);
    }

    // Keep 1 second of sustained readings
    while (_sustainedAccelerations.length > (1000 / ACCELERATION_WINDOW_MS)) {
      _sustainedAccelerations.removeAt(0);
    }

    _currentAcceleration = acceleration;
  }

  void _startSensorMonitoring() {
    // Accelerometer monitoring with higher frequency
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final acceleration =
          sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      _processAcceleration(acceleration);
    });

    // Gyroscope monitoring
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      _currentAngularVelocity =
          sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    });

    // Location monitoring
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_processLocation);

    // Start acceleration processing timer
    _accelerationTimer =
        Timer.periodic(Duration(milliseconds: ACCELERATION_WINDOW_MS), (_) {
      _processAccelerationWindow();
    });
  }

  void _processAccelerationWindow() {
    if (_recentAccelerations.isEmpty) return;

    // Calculate average and peak accelerations
    double avgAcceleration = _sustainedAccelerations.reduce((a, b) => a + b) /
        _sustainedAccelerations.length;
    double peakAcceleration = _recentAccelerations.reduce(max);

    // Check if conditions meet accident criteria
    if (_isValidAccidentScenario(peakAcceleration, avgAcceleration)) {
      _checkForAccident(
          'Significant impact detected: ${peakAcceleration.toStringAsFixed(1)} m/s²');
    }

    _recentAccelerations.clear();
  }

  void _processLocation(Position position) {
    if (_lastPosition == null || _lastSpeedCheck == null) {
      _lastPosition = position;
      _lastSpeedCheck = DateTime.now();
      _lastSpeed = position.speed;
      return;
    }

    final now = DateTime.now();
    final duration = now.difference(_lastSpeedCheck!);

    if (duration.inMilliseconds > 500) {
      final speedChange = (position.speed - _lastSpeed).abs();

      if (speedChange > SUDDEN_SPEED_CHANGE_THRESHOLD &&
          position.speed > SPEED_THRESHOLD) {
        _checkForAccident(
            'Sudden speed change: ${speedChange.toStringAsFixed(1)} m/s');
      }

      _lastSpeed = position.speed;
      _lastSpeedCheck = now;
    }

    _lastPosition = position;
  }

  bool _isValidAccidentScenario(
      double peakAcceleration, double avgAcceleration) {
    if (_lastPosition == null) return false;

    // Speed must be above threshold for impact detection
    if (_lastSpeed < SPEED_THRESHOLD) return false;

    // Check various accident conditions
    bool isHighImpact = peakAcceleration > ACCELERATION_THRESHOLD;
    bool isSustainedImpact = avgAcceleration > SUSTAINED_ACCELERATION_THRESHOLD;
    bool isRotational = _currentAngularVelocity > ANGULAR_VELOCITY_THRESHOLD;

    // Must meet impact criteria and either sustained force or rotation
    return isHighImpact && (isSustainedImpact || isRotational);
  }

  void _checkForAccident(String reason) {
    // Prevent multiple detections in quick succession
    if (_isProcessingAccident) return;

    final now = DateTime.now();
    if (_lastAccidentTime != null &&
        now.difference(_lastAccidentTime!).inMilliseconds <
            DETECTION_COOLDOWN_MS) {
      return;
    }

    _isProcessingAccident = true;
    _lastAccidentTime = now;

    try {
      if (_lastPosition != null) {
        final accidentData = AccidentData(
          timestamp: now,
          location: _lastPosition!,
          acceleration: _currentAcceleration,
          angularVelocity: _currentAngularVelocity,
          speed: _lastSpeed,
          reason: reason,
        );

        onAccidentDetected(accidentData);
      }
    } finally {
      // Reset processing flag after a short delay
      Future.delayed(Duration(seconds: 1), () {
        _isProcessingAccident = false;
      });
    }
  }

  Future<void> _requestPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sensors,
      Permission.location,
      Permission.phone,
      Permission.sms,
    ].request();

    // Check for denied permissions
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${permission.toString()} permission is required')),
        );
      }
    });
  }

  void _startAccelerometerMonitoring() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      // Calculate total acceleration using 3-axis data
      _currentAcceleration =
          sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

      if (_currentAcceleration > ACCELERATION_THRESHOLD) {
        _checkForAccident(
            'High acceleration detected: ${_currentAcceleration.toStringAsFixed(1)} m/s²');
      }
    });
  }

  void _startGyroscopeMonitoring() {
    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      // Calculate total angular velocity
      _currentAngularVelocity =
          sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

      if (_currentAngularVelocity > ANGULAR_VELOCITY_THRESHOLD) {
        _checkForAccident(
            'High angular velocity detected: ${_currentAngularVelocity.toStringAsFixed(1)} rad/s');
      }
    });
  }

  void _startLocationMonitoring() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _checkSuddenSpeedChange(position);
      _lastPosition = position;
    });
  }

  void _checkSuddenSpeedChange(Position currentPosition) {
    if (_lastPosition == null || _lastSpeedCheck == null) {
      _lastPosition = currentPosition;
      _lastSpeedCheck = DateTime.now();
      _lastSpeed = currentPosition.speed;
      return;
    }

    final now = DateTime.now();
    final duration = now.difference(_lastSpeedCheck!);

    if (duration.inMilliseconds > 500) {
      // Check every 500ms
      final speedChange = (currentPosition.speed - _lastSpeed).abs();

      if (speedChange > SUDDEN_SPEED_CHANGE_THRESHOLD) {
        _checkForAccident(
            'Sudden speed change detected: ${speedChange.toStringAsFixed(1)} m/s');
      }

      _lastSpeed = currentPosition.speed;
      _lastSpeedCheck = now;
    }
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _locationSubscription?.cancel();
    _accelerationTimer?.cancel();
    _recentAccelerations.clear();
    _sustainedAccelerations.clear();
  }
}

class AccidentData {
  final DateTime timestamp;
  final Position location;
  final double acceleration;
  final double angularVelocity;
  final double speed;
  final String reason;

  AccidentData({
    required this.timestamp,
    required this.location,
    required this.acceleration,
    required this.angularVelocity,
    required this.speed,
    required this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': location.latitude,
      'longitude': location.longitude,
      'acceleration': acceleration,
      'angularVelocity': angularVelocity,
      'speed': speed,
      'reason': reason,
    };
  }
}

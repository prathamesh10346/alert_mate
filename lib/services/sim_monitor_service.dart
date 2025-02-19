// lib/services/sim_monitor_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimMonitorService {
  static final SimMonitorService _instance = SimMonitorService._internal();
  factory SimMonitorService() => _instance;
  SimMonitorService._internal();

  static const platform = MethodChannel('com.example.alert_mate/sim_monitor');
  static const eventChannel = EventChannel('com.example.alert_mate/sim_events');
  final _simChangeController = StreamController<SimChangeEvent>.broadcast();

  Stream<SimChangeEvent> get onSimChange => _simChangeController.stream;

  Future<void> initialize() async {
    // Set up event channel listener
    eventChannel.receiveBroadcastStream().listen(_handleSimChangeEvent);

    // Initialize monitoring
    try {
      await platform.invokeMethod('initializeSimMonitoring');
    } catch (e) {
      print('Error initializing SIM monitoring: $e');
    }
  }

  void _handleSimChangeEvent(dynamic event) {
    if (event is Map) {
      final simEvent = SimChangeEvent(
        previousSim: event['previous_sim'] as String? ?? '',
        currentSim: event['current_sim'] as String? ?? '',
        timestamp: DateTime.now(),
      );
      _simChangeController.add(simEvent);
      _saveSimChangeHistory(simEvent);
    }
  }

  Future<void> _saveSimChangeHistory(SimChangeEvent event) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('sim_change_history') ?? [];
    history.add(event.toString());
    await prefs.setStringList('sim_change_history', history);
  }

  Future<List<SimChangeEvent>> getSimChangeHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('sim_change_history') ?? [];
    return history.map((e) => SimChangeEvent.fromString(e)).toList();
  }

  Future<void> dispose() async {
    await _simChangeController.close();
  }
}

class SimChangeEvent {
  final String previousSim;
  final String currentSim;
  final DateTime timestamp;

  SimChangeEvent({
    required this.previousSim,
    required this.currentSim,
    required this.timestamp,
  });

  @override
  String toString() {
    return '$previousSim|$currentSim|${timestamp.toIso8601String()}';
  }

  static SimChangeEvent fromString(String str) {
    final parts = str.split('|');
    return SimChangeEvent(
      previousSim: parts[0],
      currentSim: parts[1],
      timestamp: DateTime.parse(parts[2]),
    );
  }
}

// sim_monitor_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimMonitorScreen extends StatefulWidget {
  @override
  _SimMonitorScreenState createState() => _SimMonitorScreenState();
}

class _SimMonitorScreenState extends State<SimMonitorScreen> {
  static const platform = MethodChannel('com.your.app/sim_monitor');
  bool isMonitoringEnabled = false;
  Map<String, dynamic> currentSimInfo = {};
  Map<String, dynamic>? storedSimInfo;
  String? storedSimId;
  String currentSimId = 'Unknown';
  Map<String, dynamic> currentSimDetails = {};
  Map<String, dynamic>? storedSimDetails;

  @override
  void initState() {
    super.initState();
    _loadSimState();
    _setupSimMonitoring();
    _getSimDetails();
  }

  Future<void> _loadSimState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isMonitoringEnabled = prefs.getBool('sim_monitoring_enabled') ?? false;
      final storedSimInfoString = prefs.getString('stored_sim_info');
      if (storedSimInfoString != null) {
        storedSimInfo = Map<String, dynamic>.from(
            Map.from(json.decode(storedSimInfoString)));
      }
    });
    if (isMonitoringEnabled) {
      _startSimMonitoring();
    }
  }

  Future<void> _setupSimMonitoring() async {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onSimChanged') {
        final simInfo = Map<String, dynamic>.from(call.arguments);

        if (storedSimInfo != null &&
            (storedSimInfo!['simOperator'] != simInfo['simOperator'] ||
                storedSimInfo!['simOperatorName'] !=
                    simInfo['simOperatorName'])) {
          _showSimChangeAlert();
        }
      }
      return null;
    });
  }

  Future<void> _toggleMonitoring(bool value) async {
    try {
      if (value) {
        final simInfo = await platform.invokeMethod('startSimMonitoring');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('stored_sim_info', json.encode(simInfo));
        await prefs.setBool('sim_monitoring_enabled', true);
        setState(() {
          isMonitoringEnabled = true;
          storedSimInfo = Map<String, dynamic>.from(simInfo);
        });
      } else {
        await platform.invokeMethod('stopSimMonitoring');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('sim_monitoring_enabled', false);
        setState(() {
          isMonitoringEnabled = false;
        });
      }
    } catch (e) {
      print('Error toggling monitoring: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showSimChangeAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('⚠️ SIM Card Change Detected!'),
          content: Text('A change in the SIM card has been detected.'),
          actions: <Widget>[
            TextButton(
              child: Text('Acknowledge'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentSimId() async {
    try {
      final String simId = await platform.invokeMethod('getSimId');
      setState(() {
        currentSimId = simId;
      });
    } catch (e) {
      print('Error getting SIM ID: $e');
    }
  }

  Future<void> _startSimMonitoring() async {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onSimChanged') {
        String newSimId = call.arguments['simId'];
        if (storedSimId != null && storedSimId != newSimId) {
          _showSimChangeAlert();
        }
      }
      return null;
    });
  }

  Future<void> _getSimDetails() async {
    try {
      final details = await platform.invokeMethod('getSimDetails');
      setState(() {
        currentSimDetails = Map<String, dynamic>.from(details);
      });
    } catch (e) {
      print('Error getting SIM details: $e');
    }
  }

  Widget _buildSimCardInfo() {
    if (currentSimDetails.isEmpty) {
      return Text('Loading SIM details...');
    }

    List<Widget> simCards = [];
    List<dynamic> simCardsList = currentSimDetails['simCards'] ?? [];

    for (var simCard in simCardsList) {
      simCards.add(
        Card(
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Slot: ${simCard['slotIndex'] + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Carrier: ${simCard['carrierName']}'),
                Text('Number: ${simCard['phoneNumber']}'),
                Text('Operator: ${simCard['simOperatorName']}'),
                Text('Country: ${simCard['countryIso']}'),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Number of SIMs: ${currentSimDetails['numberOfSims']}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        ...simCards,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SIM Card Monitor'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                isMonitoringEnabled ? Icons.sim_card_alert : Icons.sim_card,
                size: 100,
                color: isMonitoringEnabled ? Colors.green : Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                isMonitoringEnabled
                    ? 'SIM Monitoring Active'
                    : 'SIM Monitoring Inactive',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Container(
                height: 200,
                child: storedSimInfo == null
                    ? Center(child: Text('No SIM information available'))
                    : ListView(
                        children: storedSimInfo!.entries.map((entry) {
                          return ListTile(
                            title: Text(entry.key),
                            subtitle: Text(entry.value.toString()),
                          );
                        }).toList(),
                      ),
              ),
              SizedBox(height: 40),
              Switch(
                value: isMonitoringEnabled,
                onChanged: _toggleMonitoring,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

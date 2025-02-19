import 'dart:convert';

import 'package:alert_mate/screen/AccidentDetectionScreen.dart';
import 'package:alert_mate/screen/SimMonitorScreen.dart';
import 'package:alert_mate/screen/anti_pocket_screen.dart';
import 'package:alert_mate/screen/bluetooth_proximity_screen.dart';
import 'package:alert_mate/screen/connectivity_lock_screen.dart';
import 'package:alert_mate/screen/do_not_touch_screen.dart';
import 'package:alert_mate/screen/geofencing_screen.dart';
import 'package:alert_mate/screen/intruder_selfie_screen.dart';
import 'package:alert_mate/screen/theft_mode_screen.dart';
import 'package:alert_mate/screen/un_plug_protection.dart';
import 'package:alert_mate/screen/vault_screen.dart';
import 'package:alert_mate/screen/voice_command_screen.dart';
import 'package:alert_mate/screen/women_safety_screen.dart';
import 'package:alert_mate/services/bluetooth_proximity_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/device_info_service.dart';
import '../services/location_service.dart';
import '../services/wifi_service.dart';
import '../services/phone_service.dart';
import 'call_logs_screen.dart';

class DeviceDetailsScreen extends StatefulWidget {
  @override
  _DeviceDetailsscreentate createState() => _DeviceDetailsscreentate();
}

class _DeviceDetailsscreentate extends State<DeviceDetailsScreen> {
  Map<String, dynamic> deviceDetails = {};
  bool isLoading = false;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();
  final LocationService _locationService = LocationService();
  final WifiService _wifiService = WifiService();
  final PhoneService _phoneService = PhoneService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.phone.request();
    await Permission.sms.request();
    await Permission.location.request();
    // Check if permissions were granted
    if (!await Permission.phone.isGranted || !await Permission.sms.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Phone and SMS permissions are required for emergency calls')),
      );
    }
  }

  Future<void> fetchDeviceDetails() async {
    setState(() => isLoading = true);

    try {
      await _requestPermissions();

      if (await Permission.phone.isGranted) {
        final deviceInfo = await _deviceInfoService.getDeviceInformation();
        final locationInfo = await _locationService.fetchLocationDetails();
        final wifiInfo = await _wifiService.fetchWifiInfo();
        final phoneInfo = await _phoneService.getPhoneAndBatteryInfo();

        setState(() {
          deviceDetails = {
            ...deviceInfo,
            ...locationInfo,
            ...wifiInfo,
            ...phoneInfo,
          };
        });
      } else {
        setState(() {
          deviceDetails = {"Error": "Phone permission not granted"};
        });
      }
    } catch (e) {
      setState(() {
        deviceDetails = {"Error": "Failed to fetch details: $e"};
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Details App'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: isLoading ? null : fetchDeviceDetails,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Get Device Details'),
              ),
              SizedBox(height: 16),

              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {},
                child: Text('View Call Logs'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AccidentDetectionScreen()),
                  );
                },
                child: Text('Accident Detection'),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildQRCode(deviceDetails),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Close'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Text('Generate Device QR Code'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AntiPocketScreen()),
                  );
                },
                child: Text('Anti-Pocket Protection'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DoNotTouchScreen()),
                  );
                },
                child: Text('Do Not Touch Protection'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UnplugProtectionScreen()),
                  );
                },
                child: Text('Unplug Protection'),
              ),
              // In DeviceDetailsScreen class
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TheftModeScreen()),
                  );
                },
                child: Text('Theft Mode'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => WomenSafetyScreen()),
                  );
                },
                child: Text('Women Safty'),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AirplaneModeMonitor()),
                  );
                },
                child: Text('Connectivity Lock'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => IntruderSelfieScreen()),
                  );
                },
                child: Text('Intruder Selfie'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SimMonitorScreen()),
                  );
                },
                child: Text('SIM Monitor'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BluetoothProximityScreen()),
                  );
                },
                child: Text('Bluetooth Proximity Alerts'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GeofencingScreen()),
                  );
                },
                child: Text('Geo-Fencing'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VaultScreen()),
                  );
                },
                child: Text('Vault '),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => VoiceCommandScreen()),
                  );
                },
                child: Text('Voice Activation  '),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCode(Map<String, dynamic> deviceDetails) {
    // Convert device details to JSON string
    final String deviceInfoJson = jsonEncode(deviceDetails);

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          child: QrImageView(
            data: deviceInfoJson,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
          ),
        ),
        Text(
          'Scan this QR code to get device details',
          style: TextStyle(fontSize: 16),
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'If device is misplaced, this QR code contains\ncontact and device information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Map<String, String> details) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Table(
            border: TableBorder.all(),
            columnWidths: {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
            },
            children: details.entries.map((entry) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      entry.key,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(entry.value),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Future<void> _navigateToCallLogs(BuildContext context) async {
  //   var status = await Permission.phone.status;
  //   if (!status.isGranted) {
  //     await Permission.phone.request();
  //   }
  //   if (await Permission.phone.isGranted) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => CallLogsScreen()),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //           content: Text('Phone permission is required to view call logs')),
  //     );
  //   }
  // }
}

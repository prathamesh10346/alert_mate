import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BluetoothProximityScreen extends StatefulWidget {
  @override
  _BluetoothProximityScreenState createState() =>
      _BluetoothProximityScreenState();
}

class _BluetoothProximityScreenState extends State<BluetoothProximityScreen> {
  static const platform = MethodChannel('com.your.app/bluetooth_proximity');
  bool isMonitoring = false;
  List<DeviceInfo> devices = [];
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupProximityListeners();
  }

  void _setupProximityListeners() {
    platform.setMethodCallHandler((call) async {
      print(
          'FULL METHOD CALL RECEIVED: method=${call.method}, arguments=${call.arguments}');

      try {
        switch (call.method) {
          case 'updateDevices':
            final List<dynamic> devicesList = call.arguments;
            setState(() {
              devices = devicesList.map((d) => DeviceInfo.fromMap(d)).toList();
            });
            break;
          case 'proximityAlert':
            // Robust type conversion
            final Map<String, dynamic> alertData =
                _convertToStringDynamicMap(call.arguments);

            print('PROXIMITY ALERT TRIGGERED: $alertData');

            // Forceful dialog display with multiple methods
            _showProximityAlertDialog(alertData);
            _showSnackBarAlert(alertData);
            _showSystemAlert(alertData);
            break;
        }
      } catch (e) {
        print('ERROR IN METHOD HANDLER: $e');
      }

      return null;
    });
  }

// Helper method to convert dynamic map to Map<String, dynamic>
  Map<String, dynamic> _convertToStringDynamicMap(dynamic arguments) {
    if (arguments is Map<String, dynamic>) {
      return arguments;
    }

    // If it's a Map with Object? keys, convert it
    if (arguments is Map) {
      return arguments.map((key, value) => MapEntry(key.toString(), value));
    }

    // If conversion fails, return a default map
    print('WARNING: Unexpected arguments type: ${arguments.runtimeType}');
    return {'name': 'Unknown Device', 'distance': 0.0, 'address': ''};
  }

  void _showProximityAlertDialog(Map<String, dynamic> alertData) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(navigatorKey.currentContext!, rootNavigator: true).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (BuildContext context, _, __) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text(
                'Proximity Alert!',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Device "${alertData['name'] ?? 'Unknown'}"\n'
                'Distance: ${(alertData['distance'] ?? 0.0).toStringAsFixed(2)} meters\n'
                'Status: Out of Range',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true)
                        .popUntil((route) => route.isFirst);
                  },
                  child: Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
              backgroundColor: Colors.white,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut,
                ),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        ),
      );
    });
  }

  void _showSnackBarAlert(Map<String, dynamic> alertData) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(
            'Proximity Alert: Device ${alertData['name'] ?? 'Unknown'} out of range!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 10),
      ),
    );
  }

  void _showSystemAlert(Map<String, dynamic> alertData) {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('CRITICAL PROXIMITY ALERT',
              style: TextStyle(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Device: ${alertData['name'] ?? 'Unknown'}'),
              Text(
                  'Distance: ${(alertData['distance'] ?? 0.0).toStringAsFixed(2)} meters'),
              Text('Status: OUT OF RANGE',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('ACKNOWLEDGE', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleMonitoring() async {
    try {
      if (isMonitoring) {
        await platform.invokeMethod('stopMonitoring');
      } else {
        await platform.invokeMethod('startMonitoring');
      }
      setState(() {
        isMonitoring = !isMonitoring;
      });
    } catch (e) {
      print('Monitoring toggle error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey, // Use the new navigator
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Bluetooth Proximity Monitor'),
          ),
          body: Column(
            children: [
              SwitchListTile(
                title: Text('Enable Proximity Monitoring'),
                value: isMonitoring,
                onChanged: (_) => _toggleMonitoring(),
              ),
              Expanded(
                child: devices.isEmpty
                    ? Center(child: Text('No connected devices detected'))
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          print(
                              'Rendering device: ${device.name}, Distance: ${device.distance}, isConnected: ${device.isConnected}');
                          return ListTile(
                            title: Text(device.name),
                            subtitle: Text(
                              'Distance: ${device.distance.toStringAsFixed(2)} meters',
                            ),
                            trailing: Icon(
                              device.isConnected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth_disabled,
                              color: device.isConnected
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceInfo {
  final String name;
  final String address;
  final bool isConnected;
  final double distance;
  final int signalStrength;

  DeviceInfo({
    required this.name,
    required this.address,
    required this.distance,
    required this.isConnected,
    required this.signalStrength,
  });
  factory DeviceInfo.fromMap(Map<dynamic, dynamic> map) {
    return DeviceInfo(
      name: map['name'] ?? 'Unknown Device',
      address: map['address'] ?? '',
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      signalStrength: map['signalStrength'] ?? 0,
      isConnected: map['isConnected'] ?? false,
    );
  }
}

import 'package:alert_mate/screen/devies_details/geofencescreen.dart';
import 'package:flutter/material.dart';
import '../../services/geofencing_service.dart';

class GeofencingScreen extends StatefulWidget {
  @override
  _GeofencingScreenState createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  final GeofencingService _geofencingService = GeofencingService();
  List<GeoFenceStatus> _statuses = [];
  bool _isMonitoring = false;
  @override
  void initState() {
    // GeofencingService.initializeService();
    // TODO: implement initState
    super.initState();
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });

    if (_isMonitoring) {
      _geofencingService.monitorGeofences().listen((status) {
        setState(() {
          var existingIndex =
              _statuses.indexWhere((s) => s.fenceId == status.fenceId);
          if (existingIndex != -1) {
            _statuses[existingIndex] = status;
          } else {
            _statuses.add(status);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Geo-Fencing Monitor')),
      body: Column(
        children: [
          SwitchListTile(
            title: Text('Enable Geo-Fencing'),
            value: _isMonitoring,
            onChanged: (_) => _toggleMonitoring(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _statuses.length,
              itemBuilder: (context, index) {
                var status = _statuses[index];
                return ListTile(
                  title: Text(status.name),
                  subtitle: Text(
                    status.isInside ? 'Inside Zone' : 'Outside Zone',
                    style: TextStyle(
                        color: status.isInside ? Colors.green : Colors.red),
                  ),
                  trailing: Text(status.timestamp.toString().substring(0, 19)),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

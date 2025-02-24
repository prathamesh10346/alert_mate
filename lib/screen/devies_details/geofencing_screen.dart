import 'package:alert_mate/screen/devies_details/geofencescreen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/geofencing_service.dart';

class GeofencingScreen extends StatefulWidget {
  @override
  _GeofencingScreenState createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends State<GeofencingScreen> {
  final GeofencingService _geofencingService = GeofencingService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _radiusController = TextEditingController();

  GoogleMapController? _mapController;
  List<GeoFenceStatus?> _statuses = [];
  bool _isMonitoring = false;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  // Default center (can be updated with user's current location)
  LatLng _center = LatLng(18.84995, 73.58298);

  @override
  void initState() {
    super.initState();
    _loadExistingGeofence();
  }

  void _loadExistingGeofence() {
    if (GeofencingService.geofences.isNotEmpty) {
      final fence = GeofencingService.geofences.first;
      setState(() {
        _nameController.text = fence.name;
        _latController.text = fence.latitude.toString();
        _lngController.text = fence.longitude.toString();
        _radiusController.text = fence.radius.toString();
        _center = LatLng(fence.latitude, fence.longitude);
        _updateMapCircle();
      });
    }
  }

  void _updateMapCircle() {
    setState(() {
      _circles.clear();
      _markers.clear();

      _circles.add(Circle(
        circleId: CircleId('geofence'),
        center: _center,
        radius: double.tryParse(_radiusController.text) ?? 500,
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ));

      _markers.add(Marker(
        markerId: MarkerId('center'),
        position: _center,
        draggable: true,
        onDragEnd: (LatLng position) {
          setState(() {
            _center = position;
            _latController.text = position.latitude.toString();
            _lngController.text = position.longitude.toString();
            _updateMapCircle();
          });
        },
      ));
    });
  }

  void _saveGeofence() {
    FocusScope.of(context).unfocus();
    final newFence = GeoFence(
      id: '1',
      name: _nameController.text,
      latitude: double.parse(_latController.text),
      longitude: double.parse(_lngController.text),
      radius: double.parse(_radiusController.text),
    );

    setState(() {
      GeofencingService.geofences = [newFence];
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geofence updated successfully!')));
  }

  void _toggleMonitoring() {
    setState(() {
      _isMonitoring = !_isMonitoring;
    });

    if (_isMonitoring) {
      _geofencingService.monitorGeofences().listen((status) {
        setState(() {
          var existingIndex =
              _statuses.indexWhere((s) => s!.fenceId == status.fenceId);
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Geo-Fencing Monitor',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300,
              child: GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 15,
                ),
                circles: _circles,
                markers: _markers,
                onTap: (LatLng position) {
                  setState(() {
                    _center = position;
                    _latController.text = position.latitude.toString();
                    _lngController.text = position.longitude.toString();
                    _updateMapCircle();
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                color: Colors.grey,
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Geofence Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Location Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latController,
                              decoration: InputDecoration(
                                labelText: 'Latitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _lngController,
                              decoration: InputDecoration(
                                labelText: 'Longitude',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _radiusController,
                        decoration: InputDecoration(
                          labelText: 'Radius (meters)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _updateMapCircle(),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveGeofence,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Save Geofence',
                              style: TextStyle(color: Colors.white)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SwitchListTile(
              title: Text(
                'Enable Geo-Fencing',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              value: _isMonitoring,
              onChanged: (_) => _toggleMonitoring(),
              secondary: Icon(
                  _isMonitoring ? Icons.location_on : Icons.location_off,
                  color: Colors.white),
            ),
            if (_statuses.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Monitoring History',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _statuses.length,
                itemBuilder: (context, index) {
                  var status = _statuses[index];
                  return Card(
                    color: Colors.grey,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        status!.isInside ? Icons.check_circle : Icons.warning,
                        color: status.isInside ? Colors.green : Colors.red,
                      ),
                      title: Text(status.name),
                      subtitle: Text(
                        status.isInside ? 'Inside Zone' : 'Outside Zone',
                        style: TextStyle(
                          color: status.isInside ? Colors.green : Colors.red,
                        ),
                      ),
                      trailing: Text(
                        status.timestamp.toString().substring(0, 19),
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

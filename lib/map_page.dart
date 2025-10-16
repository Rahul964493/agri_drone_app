import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<LatLng> _polygonPoints = [];
  List<Marker> _markers = [];
  final List<LatLng> _flightPathPoints = [];

  // --- NEW: LOGIC TO SAVE FIELD BOUNDARY ---
  Future<void> _showSaveFieldDialog() async {
    if (_polygonPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No field boundary to save.')),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Field'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Field Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String fieldName = nameController.text;
                if (fieldName.isNotEmpty) {
                  final prefs = await SharedPreferences.getInstance();

                  // Convert List<LatLng> to a JSON-encodable format
                  final List<Map<String, double>> pointsList = _polygonPoints
                      .map((p) => {'lat': p.latitude, 'lon': p.longitude})
                      .toList();
                  final String jsonString = jsonEncode(pointsList);

                  // Save the field data
                  await prefs.setString('field_$fieldName', jsonString);
                  
                  // Update the list of saved field names
                  final List<String> savedFields = prefs.getStringList('saved_fields') ?? [];
                  if (!savedFields.contains(fieldName)) {
                    savedFields.add(fieldName);
                    await prefs.setStringList('saved_fields', savedFields);
                  }
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Field "$fieldName" saved!')),
                  );
                }
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  // --- NEW: LOGIC TO LOAD FIELD BOUNDARY ---
  Future<void> _showLoadFieldDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedFields = prefs.getStringList('saved_fields') ?? [];

    if (savedFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved fields found.')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Load a Field'),
          children: savedFields.map((fieldName) => SimpleDialogOption(
            onPressed: () {
              final String? jsonString = prefs.getString('field_$fieldName');
              if (jsonString != null) {
                final List<dynamic> pointsList = jsonDecode(jsonString);
                final List<LatLng> loadedPoints = pointsList
                    .map((p) => LatLng(p['lat'], p['lon']))
                    .toList();
                
                _rebuildMapFromPoints(loadedPoints);
              }
              Navigator.of(context).pop();
            },
            child: Text(fieldName),
          )).toList(),
        );
      },
    );
  }

  // --- NEW: Helper function to rebuild the map state from loaded points ---
  void _rebuildMapFromPoints(List<LatLng> points) {
    // First, clear everything
    setState(() {
      _polygonPoints.clear();
      _markers.clear();
      _flightPathPoints.clear();
    });

    // Then, rebuild the state with the new points
    setState(() {
      _polygonPoints = points;
      _markers = points.map((p) => Marker(
        width: 80.0,
        height: 80.0,
        point: p,
        child: const Icon(
          Icons.location_pin,
          color: Colors.red,
          size: 40.0,
        ),
      )).toList();

      // Fit camera to the loaded polygon
      if (_polygonPoints.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(_polygonPoints),
            padding: const EdgeInsets.all(50.0),
          )
        );
      }
    });
  }


  // --- Existing Methods (no changes needed below this line) ---
  void _addMarker(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
      _markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40.0,
          ),
        ),
      );
    });
  }

  void _clearMap() {
    setState(() {
      _polygonPoints.clear();
      _markers.clear();
      _flightPathPoints.clear();
    });
  }

  Future<void> _showSpacingInputDialog() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 3 points to create a field boundary.')),
      );
      return;
    }

    final TextEditingController spacingController = TextEditingController(text: "20.0");

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Path Spacing'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Enter the distance between scan lines in meters.'),
                const SizedBox(height: 16),
                TextField(
                  controller: spacingController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Spacing (meters)',
                    suffixText: 'm',
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Generate'),
              onPressed: () {
                final double? spacing = double.tryParse(spacingController.text);
                if (spacing != null && spacing > 0) {
                  Navigator.of(context).pop();
                  _generateFlightPath(spacing);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number.'),
                      backgroundColor: Colors.redAccent,
                    )
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _generateFlightPath(double lineSpacingMeters) {
    _flightPathPoints.clear();
    const metersToLat = 1 / 111132.0;
    final double lineSpacingLat = lineSpacingMeters * metersToLat;
    double minLat = _polygonPoints.map((p) => p.latitude).reduce(min);
    double maxLat = _polygonPoints.map((p) => p.latitude).reduce(max);
    double minLon = _polygonPoints.map((p) => p.longitude).reduce(min);
    double maxLon = _polygonPoints.map((p) => p.longitude).reduce(max);
    final List<List<LatLng>> pathSegments = [];
    for (double lat = minLat; lat <= maxLat; lat += lineSpacingLat) {
      final List<double> intersections = [];
      for (int i = 0; i < _polygonPoints.length; i++) {
        LatLng p1 = _polygonPoints[i];
        LatLng p2 = _polygonPoints[(i + 1) % _polygonPoints.length];
        if ((p1.latitude <= lat && p2.latitude > lat) || (p2.latitude <= lat && p1.latitude > lat)) {
          double intersectLon = p1.longitude + (lat - p1.latitude) * (p2.longitude - p1.longitude) / (p2.latitude - p1.latitude);
          if (intersectLon >= minLon && intersectLon <= maxLon) {
             intersections.add(intersectLon);
          }
        }
      }
      intersections.sort();
      for (int i = 0; i < intersections.length; i += 2) {
        if (i + 1 < intersections.length) {
          pathSegments.add([
            LatLng(lat, intersections[i]),
            LatLng(lat, intersections[i+1])
          ]);
        }
      }
    }
    for (int i = 0; i < pathSegments.length; i++) {
      List<LatLng> segment = pathSegments[i];
      if (i % 2 == 0) {
        _flightPathPoints.add(segment[0]);
        _flightPathPoints.add(segment[1]);
      } else {
        _flightPathPoints.add(segment[1]);
        _flightPathPoints.add(segment[0]);
      }
    }
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Flight path generated with ${lineSpacingMeters}m spacing!')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Mapping'),
        actions: [
          // --- NEW: SAVE AND LOAD BUTTONS ---
          IconButton(
            icon: const Icon(Icons.save_alt_outlined),
            onPressed: _showSaveFieldDialog,
            tooltip: 'Save Field',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: _showLoadFieldDialog,
            tooltip: 'Load Field',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearMap,
            tooltip: 'Clear Map',
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(21.2514, 81.6296),
          initialZoom: 16.0,
          onTap: (tapPosition, point) => _addMarker(point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.example.agri_drone_final',
            maxNativeZoom: 19,
            maxZoom: 22,
          ),
          if (_polygonPoints.length > 2)
            PolygonLayer(
              polygons: [
                  Polygon(
                    points: _polygonPoints,
                    color: Colors.yellow.withOpacity(0.4),
                    borderColor: Colors.yellow,
                    borderStrokeWidth: 3,
                  ),
              ],
            ),
          if (_flightPathPoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _flightPathPoints,
                  strokeWidth: 4.0,
                  color: Colors.cyanAccent,
                ),
              ],
            ),
          if (_markers.isNotEmpty)
            MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSpacingInputDialog,
        label: const Text('Generate Path'),
        icon: const Icon(Icons.route),
      ),
    );
  }
}
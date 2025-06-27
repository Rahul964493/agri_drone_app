import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final List<LatLng> _polygonPoints = [];
  final List<Marker> _markers = [];

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
    });
  }

  // This function is a placeholder for now
  void _generateFlightPath() {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate the field polygon first.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Flight path generation logic would be implemented here!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Mapping'),
        actions: [
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
          initialCenter: LatLng(21.2514, 81.6296), // Raipur, Chhattisgarh
          initialZoom: 12.0,
          onTap: (tapPosition, point) => _addMarker(point),
        ),
        children: [
          TileLayer(
            // Switched to a satellite imagery provider
            urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'com.example.agri_drone_final',
            // It is recommended to set maxNativeZoom to the server's maximum.
            // This prevents blurry tiles when zooming in too far.
            maxNativeZoom: 19,
            maxZoom: 22,
          ),
          PolygonLayer(
            polygons: [
              if (_polygonPoints.length > 2)
                Polygon(
                  points: _polygonPoints,
                  color: Colors.yellow.withAlpha(102),
                  borderColor: Colors.yellow,
                  borderStrokeWidth: 2,
                ),
            ],
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateFlightPath,
        label: const Text('Generate Path'),
        icon: const Icon(Icons.route),
      ),
    );
  }
}
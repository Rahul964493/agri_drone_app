import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // The controller for the map
  GoogleMapController? _mapController;
  
  // The set of markers that will be displayed on the map
  final Set<Marker> _markers = HashSet<Marker>();

  // The set of polygons that will be displayed on the map
  final Set<Polygon> _polygons = HashSet<Polygon>();

  // The list of latitude-longitude points that define the polygon's vertices
  final List<LatLng> _polygonLatLngs = <LatLng>[];

  // A unique ID for the polygon
  final String _polygonId = "field_polygon_1";

  // The initial camera position when the map loads
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(21.2514, 81.6296), // Centered on Raipur, Chhattisgarh
    zoom: 12.0,
  );

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Function to handle map taps and add markers
  void _onMapTap(LatLng latLng) {
    setState(() {
      _polygonLatLngs.add(latLng);
      _markers.add(
        Marker(
          markerId: MarkerId('marker_${_markers.length}'),
          position: latLng,
          infoWindow: InfoWindow(
            title: 'Point ${_markers.length + 1}',
            snippet: '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}',
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
    });
  }

  // Function to generate the polygon from the added markers
  void _generatePolygon() {
    if (_polygonLatLngs.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 3 markers to create a field.')),
      );
      return;
    }

    setState(() {
      _polygons.clear();
      _polygons.add(
        Polygon(
          polygonId: PolygonId(_polygonId),
          points: _polygonLatLngs,
          strokeWidth: 2,
          strokeColor: Colors.yellow,
          fillColor: Colors.yellow.withOpacity(0.35),
        ),
      );
    });
  }
  
  // Function to generate the flight path (stub for now)
  void _generateFlightPath() {
      if (_polygons.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please generate the field polygon first.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight path generation logic would be implemented here!')),
        );
  }

  // Function to clear all markers and polygons
  void _clearMap() {
    setState(() {
      _markers.clear();
      _polygons.clear();
      _polygonLatLngs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Mapping & Mission Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearMap,
            tooltip: 'Clear Map',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: _initialCameraPosition,
            mapType: MapType.satellite,
            markers: _markers,
            polygons: _polygons,
            onTap: _onMapTap,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: _generatePolygon,
                  label: const Text('Draw Field'),
                  icon: const Icon(Icons.edit),
                  heroTag: 'fab1',
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  onPressed: _generateFlightPath,
                  label: const Text('Generate Path'),
                  icon: const Icon(Icons.route),
                  heroTag: 'fab2',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
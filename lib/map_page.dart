import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'report_viewer.dart'; // Ensure this exists

class MapPage extends StatefulWidget {
  // ADDED: Parameter to accept data from Dashboard
  final String? preSelectedAnalysis; 
  
  const MapPage({super.key, this.preSelectedAnalysis});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<LatLng> _polygonPoints = [];
  List<Marker> _markers = [];
  
  // UPDATE WITH YOUR SERVER IP
  final String _serverUrl = 'http://192.168.0.217:5000';

  // --- THEME COLORS ---
  final Color _darkBg = const Color(0xFF121212);
  final Color _cardBg = const Color(0xFF1E1E1E);
  final Color _accentGreen = const Color(0xFF00E676); 
  final Color _accentBlue = const Color(0xFF2979FF); 
  
  void _addMarker(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
      _markers.add(Marker(width: 80.0, height: 80.0, point: point, child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 40.0)));
    });
  }

  void _clearMap() {
    setState(() { _polygonPoints.clear(); _markers.clear(); });
  }

  // Step 1: Input Field Name
  Future<void> _showSaveFieldDialog() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mark field boundary first (min 3 points).'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }
    final TextEditingController nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: const Text('Save Field', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController, 
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Field Name',
              labelStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[700]!)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentGreen)),
              prefixIcon: const Icon(Icons.landscape, color: Colors.grey),
            )
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey[400]))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accentGreen, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                if (nameController.text.isNotEmpty) {
                  // --- CHANGED LOGIC HERE ---
                  if (widget.preSelectedAnalysis != null) {
                    // DIRECT EXECUTION: Use value from Dashboard
                    _processFieldOnServer(nameController.text, widget.preSelectedAnalysis!);
                  } else {
                    // Fallback (if accessed directly, though unlikely now)
                    _showAnalysisTypeDialog(nameController.text);
                  }
                }
              },
              child: const Text('Start Analysis'),
            ),
          ],
        );
      },
    );
  }

  // Step 2: Select Analysis Type (Fallback)
  void _showAnalysisTypeDialog(String fieldName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('Select Analysis Type', style: TextStyle(color: Colors.white)),
        content: Text('Choose the type of analysis to perform on the server.', style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.monitor_heart_outlined, color: _accentBlue),
            onPressed: () {
              Navigator.pop(context);
              _processFieldOnServer(fieldName, "Crop Health Monitoring");
            },
            label: Text('Crop Health', style: TextStyle(color: _accentBlue)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.grass, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              _processFieldOnServer(fieldName, "Soil Analysis");
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentGreen, foregroundColor: Colors.black),
            label: const Text('Soil Analysis'),
          ),
        ],
      ),
    );
  }

  // Step 3: Send to Server
  Future<void> _processFieldOnServer(String name, String analysisType) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)));

    try {
      List<Map<String, double>> coordsJson = _polygonPoints.map((p) => {'lat': p.latitude, 'lon': p.longitude}).toList();
      
      final response = await http.post(
        Uri.parse('$_serverUrl/upload_field'),
        body: jsonEncode({
          'field_name': name,
          'coordinates': coordsJson,
          'analysis_type': analysisType 
        }),
      ).timeout(const Duration(minutes: 5));

      Navigator.pop(context);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['data'] != null) {
             _showVisualResults(data['data']);
        } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Request Processed'), backgroundColor: _cardBg));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server Error: ${response.body}'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  // Visual Results
  void _showVisualResults(Map<String, dynamic> data) {
    // Determine view mode based on what analysis was just run
    String initialMode = 'soil';
    if (widget.preSelectedAnalysis != null) {
      initialMode = (widget.preSelectedAnalysis == "Crop Health Monitoring") ? 'health' : 'soil';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FieldReportSheet(data: data, initialView: initialMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Title
    String title = "Field Survey";
    if (widget.preSelectedAnalysis == "Soil Analysis") title = "Soil Survey";
    if (widget.preSelectedAnalysis == "Crop Health Monitoring") title = "Health Survey";

    return Scaffold(
      extendBodyBehindAppBar: true, 
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5), 
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.cloud_sync, color: Colors.white), tooltip: 'Process Field', onPressed: _showSaveFieldDialog),
          IconButton(icon: const Icon(Icons.delete, color: Colors.white), tooltip: 'Clear', onPressed: _clearMap),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: const LatLng(21.2514, 81.6296), initialZoom: 16.0, onTap: (tapPosition, point) => _addMarker(point)),
        children: [
          TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'),
          if (_polygonPoints.length > 2) PolygonLayer(polygons: [Polygon(points: _polygonPoints, color: _accentBlue.withOpacity(0.3), borderColor: _accentBlue, borderStrokeWidth: 3)]),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
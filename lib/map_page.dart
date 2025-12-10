import 'dart:convert';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  List<LatLng> _polygonPoints = [];
  List<Marker> _markers = [];
  
  // UPDATE WITH YOUR SERVER IP
  final String _serverUrl = 'http://192.168.0.217:5000';

  void _addMarker(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
      _markers.add(Marker(width: 80.0, height: 80.0, point: point, child: const Icon(Icons.location_pin, color: Colors.red, size: 40.0)));
    });
  }

  void _clearMap() {
    setState(() { _polygonPoints.clear(); _markers.clear(); });
  }

  // Step 1: Input Field Name
  Future<void> _showSaveFieldDialog() async {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mark field boundary first (min 3 points).')));
      return;
    }
    final TextEditingController nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Field'),
          content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Field Name')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (nameController.text.isNotEmpty) {
                  _showAnalysisTypeDialog(nameController.text);
                }
              },
              child: const Text('Start Analysis'),
            ),
          ],
        );
      },
    );
  }

  // Step 2: Select Analysis Type
  void _showAnalysisTypeDialog(String fieldName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Analysis Type'),
        content: const Text('Choose the type of analysis to perform on the server.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processFieldOnServer(fieldName, "Crop Health Monitoring");
            },
            child: const Text('Crop Health Monitoring'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processFieldOnServer(fieldName, "Soil Analysis");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('Soil Analysis'),
          ),
        ],
      ),
    );
  }

  // Step 3: Send to Server
  Future<void> _processFieldOnServer(String name, String analysisType) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

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
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Request Processed')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Server Error: ${response.body}')));
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection Error: $e')));
    }
  }

  Future<void> _showLoadDialog() async {
    try {
      final response = await http.get(Uri.parse('$_serverUrl/get_fields'));
      if (response.statusCode == 200) {
        final List<dynamic> fields = jsonDecode(response.body)['fields'];
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Load Field Report'),
            children: fields.map((name) => SimpleDialogOption(
              onPressed: () { Navigator.pop(context); _loadFieldData(name); },
              child: Padding(padding: const EdgeInsets.all(8.0), child: Text(name, style: const TextStyle(fontSize: 16))),
            )).toList(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not fetch list')));
    }
  }

  Future<void> _loadFieldData(String fieldName) async {
    try {
      final response = await http.post(Uri.parse('$_serverUrl/get_field_data'), body: jsonEncode({'field_name': fieldName}));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<dynamic> coords = data['coordinates'];
        setState(() {
          _polygonPoints = coords.map((c) => LatLng(c['lat'], c['lon'])).toList();
          _markers = _polygonPoints.map((p) => Marker(width: 80.0, height: 80.0, point: p, child: const Icon(Icons.location_pin, color: Colors.green, size: 40.0))).toList();
        });
        if (_polygonPoints.isNotEmpty) {
          _mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(_polygonPoints), padding: const EdgeInsets.all(50.0)));
        }
        _showVisualResults(data);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error loading data')));
    }
  }

  // --- 3. VISUAL RESULTS UI WITH TOGGLE SWITCH ---
  void _showVisualResults(Map<String, dynamic> data) {
    // 1. Check Data Availability
    bool hasSoil = data.containsKey('soil_analysis');
    bool hasHealth = data.containsKey('crop_health');
    String lastAction = data['last_analysis_type'] ?? data['analysis_type'] ?? "Report";

    // 2. Initial State Logic
    // Default to Health view if that was the last action, otherwise Soil
    bool initialShowHealth = (lastAction == 'Crop Health Monitoring' && hasHealth) || (!hasSoil && hasHealth);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // StatefulBuilder allows us to toggle state inside the Modal without rebuilding the whole page
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            // --- Determine which data to show based on Toggle State ---
            bool isHealthView = initialShowHealth;
            
            // Prepare Data containers
            Map<String, dynamic>? healthData = hasHealth ? data['crop_health'] : null;
            Map<String, dynamic>? soilData = hasSoil ? data['soil_analysis'] : null;

            // --- Image Logic (Reactive to View) ---
            Uint8List? mapImage;
            String? b64Str;
            
            if (isHealthView && healthData != null) {
               b64Str = healthData['health_map_image'];
            } else {
               // For Soil view, we usually fallback to Polygon map unless there's a specific image
               b64Str = null; 
            }

            if (b64Str != null && b64Str.isNotEmpty) {
              try { mapImage = base64Decode(b64Str); } catch (_) {}
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25.0))),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- HEADER WITH SWITCH ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['field_name'] ?? "Unknown", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(data['timestamp'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      // TOGGLE SWITCH
                      Row(
                        children: [
                          Text("Soil", style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: !isHealthView ? Colors.brown : Colors.grey
                          )),
                          Switch(
                            value: isHealthView,
                            activeThumbColor: Colors.green,
                            inactiveThumbColor: Colors.brown,
                            inactiveTrackColor: Colors.brown.shade100,
                            onChanged: (val) {
                              setModalState(() {
                                initialShowHealth = val; // Update the state variable
                              });
                            },
                          ),
                          Text("Health", style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isHealthView ? Colors.green : Colors.grey
                          )),
                        ],
                      )
                    ],
                  ),
                  const Divider(),

                  // --- SCROLLABLE BODY ---
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          // 1. SNAPSHOT AREA
                          if (mapImage != null)
                             Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Visual Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(mapImage, height: 200, fit: BoxFit.cover)),
                                  const SizedBox(height: 20),
                                ],
                             )
                          else if (_polygonPoints.isNotEmpty)
                             Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Field Boundary", style: TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  SizedBox(
                                    height: 200,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: FlutterMap(
                                        options: MapOptions(
                                          initialCameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(_polygonPoints), padding: const EdgeInsets.all(20)),
                                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                        ),
                                        children: [
                                          TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'),
                                          PolygonLayer(polygons: [Polygon(points: _polygonPoints, color: Colors.blue.withOpacity(0.3), borderColor: Colors.blue, borderStrokeWidth: 3)]),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                             ),

                          // 2. WEATHER (Always visible)
                          const Text("Field Weather Forecast", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSimpleStat("Rainfall", "${data['weather_forecast']?['predicted_rainfall'] ?? 0} mm"),
                                _buildSimpleStat("Temp", "${data['weather_forecast']?['avg_temperature'] ?? 0}°C"),
                                _buildSimpleStat("Season", "${data['weather_forecast']?['season'] ?? 'N/A'}"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // --- CONDITIONAL VIEW CONTENT ---
                          if (isHealthView) ...[
                              // === CROP HEALTH VIEW ===
                              if (!hasHealth)
                                 _buildNoDataMessage("Crop Health Analysis not performed yet.")
                              else ...[
                                 _buildSectionTitle("Vegetation", Colors.green),
                                 _buildInfoBox(title: "Predicted Vegetation", value: healthData!['predicted_vegetation'] ?? "N/A", color: Colors.green),
                                 const SizedBox(height: 15),

                                 _buildSectionTitle("Photosynthesis Rate", Colors.orange),
                                 _buildInfoBox(title: "Rate (Based on PAR)", value: healthData['photosynthesis_rate'] ?? "N/A", color: Colors.orange),
                                 const SizedBox(height: 15),

                                 _buildSectionTitle("Crop Status", Colors.purple),
                                 _buildInfoBox(title: "Overall Status", value: healthData['crop_status'] ?? "N/A", color: _getStatusColor(healthData['crop_status'] ?? ""), isHighlighted: true),
                                 const SizedBox(height: 15),

                                 _buildSectionTitle("Crop Diseases", Colors.redAccent),
                                 _buildInfoBox(title: "Detected Disease", value: healthData['disease_detected'] ?? "None", color: Colors.redAccent),
                                 const SizedBox(height: 15),

                                 if (data['recommendations'] != null) ...[
                                    _buildSectionTitle("Recommendations", Colors.teal),
                                    _buildRecommendation("Disease Treatment", data['recommendations']?['fertilizer_suggestions'] ?? "None"),
                                    const SizedBox(height: 10),
                                    _buildRecommendation("Management", data['recommendations']?['management_recommendations'] ?? "None"),
                                 ]
                              ]
                          ] else ...[
                              // === SOIL ANALYSIS VIEW ===
                              if (!hasSoil)
                                 _buildNoDataMessage("Soil Analysis not performed yet.")
                              else ...[
                                 const Text("Soil Composition", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
                                 const SizedBox(height: 8),
                                 Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(color: Colors.brown.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.brown.shade200)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildRow("Soil Type", soilData!['soil_type'] ?? "Unknown"),
                                        const Divider(),
                                        _buildRow("Soil Texture", soilData['soil_texture'] ?? "N/A"),
                                        const Divider(),
                                        _buildRow("Predicted Nutrients", soilData['predicted_nutrients'] ?? "N/A"),
                                        const Divider(),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                                 _buildSimpleStat("Moisture", soilData['moisture'] ?? "N/A"),
                                                 _buildSimpleStat("Humidity", soilData['humidity'] ?? "N/A"),
                                            ]
                                        )
                                      ],
                                    ),
                                 ),
                                 const SizedBox(height: 20),
                                 
                                 _buildSectionTitle("Recommendations", Colors.green),
                                 _buildRecommendation("Suitable Crops", data['crop_suggestions'] ?? "None"),
                                 const SizedBox(height: 15),
                                 if (data['soil_quality_management'] != null)
                                    _buildRecommendation("Fertilizers", data['soil_quality_management']['recommended_fertilizers'] ?? "None"),
                              ]
                          ],
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildNoDataMessage(String msg) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey, size: 40),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains("optimal") || status.contains("healthy")) return Colors.green;
    if (status.contains("critical") || status.contains("stressed") || status.contains("infected")) return Colors.red;
    if (status.contains("limit") || status.contains("monitor")) return Colors.orange;
    return Colors.purple;
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoBox({required String title, required String value, required Color color, bool isHighlighted = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: color.withOpacity(0.5), width: isHighlighted ? 2 : 1)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
  
  Widget _buildRow(String label, String value) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 13))),
                  Expanded(child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14))),
              ]
          )
      );
  }
  
  Widget _buildRecommendation(String title, String value) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(value, style: const TextStyle(fontSize: 14)),
              ]
          )
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Manager'),
        actions: [
          IconButton(icon: const Icon(Icons.cloud_sync), tooltip: 'Process Field', onPressed: _showSaveFieldDialog),
          IconButton(icon: const Icon(Icons.folder_shared), tooltip: 'Load Report', onPressed: _showLoadDialog),
          IconButton(icon: const Icon(Icons.delete), tooltip: 'Clear', onPressed: _clearMap),
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
          TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'),
          if (_polygonPoints.length > 2)
            PolygonLayer(polygons: [Polygon(points: _polygonPoints, color: Colors.blue.withOpacity(0.3), borderColor: Colors.blue, borderStrokeWidth: 3)]),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
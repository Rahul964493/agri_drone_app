import 'dart:convert';
import 'dart:typed_data'; 
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart'; 

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

  // --- THEME COLORS ---
  final Color _darkBg = const Color(0xFF121212);
  final Color _cardBg = const Color(0xFF1E1E1E);
  final Color _containerBg = const Color(0xFF2C2C2C); 
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

  Future<void> _showLoadDialog() async {
    try {
      final response = await http.get(Uri.parse('$_serverUrl/get_fields'));
      if (response.statusCode == 200) {
        final List<dynamic> fields = jsonDecode(response.body)['fields'];
        showDialog(
          context: context,
          builder: (context) => SimpleDialog(
            backgroundColor: _cardBg,
            title: const Text('Load Field Report', style: TextStyle(color: Colors.white)),
            children: fields.map((name) => SimpleDialogOption(
              onPressed: () { Navigator.pop(context); _loadFieldData(name); },
              child: Padding(padding: const EdgeInsets.all(8.0), child: Text(name, style: const TextStyle(fontSize: 16, color: Colors.white70))),
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
          _markers = _polygonPoints.map((p) => Marker(width: 80.0, height: 80.0, point: p, child: const Icon(Icons.location_pin, color: Colors.greenAccent, size: 40.0))).toList();
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

  // --- 3. VISUAL RESULTS UI (DASHBOARD STYLE) ---
  void _showVisualResults(Map<String, dynamic> data) {
    bool hasSoil = data.containsKey('soil_analysis');
    bool hasHealth = data.containsKey('crop_health');
    String lastAction = data['last_analysis_type'] ?? data['analysis_type'] ?? "Report";
    bool initialShowHealth = (lastAction == 'Crop Health Monitoring' && hasHealth) || (!hasSoil && hasHealth);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool isHealthView = initialShowHealth;
            Map<String, dynamic>? healthData = hasHealth ? data['crop_health'] : null;
            Map<String, dynamic>? soilData = hasSoil ? data['soil_analysis'] : null;

            Uint8List? mapImage;
            String? b64Str;
            if (isHealthView && healthData != null) {
               b64Str = healthData['health_map_image'];
            }
            if (b64Str != null && b64Str.isNotEmpty) {
              try { mapImage = base64Decode(b64Str); } catch (_) {}
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.9, 
              decoration: BoxDecoration(
                color: _darkBg, 
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)]
              ),
              child: Column(
                children: [
                  // --- HEADER ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['field_name'] ?? "Unknown", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(data['timestamp'] ?? "", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                          ],
                        ),
                        // Custom Toggle Switch
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[800]!)),
                          child: Row(
                            children: [
                              _buildToggleBtn("Soil", !isHealthView, () => setModalState(() => initialShowHealth = false)),
                              _buildToggleBtn("Health", isHealthView, () => setModalState(() => initialShowHealth = true)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey[800], height: 1),

                  // --- BODY ---
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          // 1. VISUALIZATION CARD (Map/Image)
                          _buildSectionContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(isHealthView ? Icons.satellite_alt : Icons.map, color: Colors.white70, size: 22),
                                  const SizedBox(width: 8),
                                  Text(isHealthView ? "NDVI Health Map" : "Field Snapshot", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                ]),
                                const SizedBox(height: 12),
                                if (mapImage != null)
                                   ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(mapImage, height: 180, width: double.infinity, fit: BoxFit.cover))
                                else if (_polygonPoints.isNotEmpty)
                                   SizedBox(
                                     height: 180,
                                     child: ClipRRect(
                                       borderRadius: BorderRadius.circular(12),
                                       child: FlutterMap(
                                         options: MapOptions(initialCameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(_polygonPoints), padding: const EdgeInsets.all(20)), interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                                         children: [TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'), PolygonLayer(polygons: [Polygon(points: _polygonPoints, color: _accentBlue.withOpacity(0.3), borderColor: _accentBlue, borderStrokeWidth: 3)])],
                                       ),
                                     ),
                                   ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 2. WEATHER SUMMARY CARD
                          _buildSectionContainer(
                            child: Column(
                              children: [
                                _buildSectionTitle("Weather Forecast", _accentBlue, Icons.cloud_queue),
                                const SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildAnimatedStat("Rainfall", "${data['weather_forecast']?['predicted_rainfall'] ?? 0} mm", _accentBlue, Icons.water_drop),
                                    _buildContainerDivider(),
                                    _buildAnimatedStat("Avg Temp", "${data['weather_forecast']?['avg_temperature'] ?? 0}°C", _accentBlue, Icons.thermostat),
                                    _buildContainerDivider(),
                                    _buildSimpleStat("Season", "${data['weather_forecast']?['season'] ?? 'N/A'}", _accentBlue, Icons.calendar_month),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // --- CONDITIONAL CONTENT ---
                          if (isHealthView) ...[
                              if (!hasHealth) _buildNoDataMessage("Crop Health Analysis not performed.")
                              else ...[
                                 // --- HEALTH DASHBOARD ---
                                 Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Expanded(
                                       flex: 4,
                                       child: _buildSectionContainer(
                                         child: Column(
                                           children: [
                                             const Text("Stress Level", style: TextStyle(color: Colors.white70, fontSize: 14)),
                                             const SizedBox(height: 10),
                                             _buildGauge(healthData!['raw_stress_pct'] ?? 0.0, Colors.redAccent),
                                           ],
                                         )
                                       ),
                                     ),
                                     const SizedBox(width: 15),
                                     Expanded(
                                       flex: 6,
                                       child: Column(
                                         children: [
                                            _buildInfoTile("Vegetation", healthData['predicted_vegetation'] ?? "N/A", Colors.greenAccent, Icons.grass),
                                            const SizedBox(height: 10),
                                            _buildInfoTile("Status", healthData['crop_status'] ?? "N/A", _getStatusColor(healthData['crop_status'] ?? ""), Icons.health_and_safety, isMain: true),
                                         ],
                                       )
                                     )
                                   ],
                                 ),
                                 const SizedBox(height: 20),
                                 
                                 _buildSectionContainer(child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                      _buildSectionTitle("Photosynthesis Rate (PAR)", Colors.orangeAccent, Icons.wb_sunny),
                                      const SizedBox(height: 15),
                                      _buildParIndicator(healthData['raw_par'] ?? 0.0),
                                      const SizedBox(height: 5),
                                      Align(alignment: Alignment.centerRight, child: Text("Value: ${(healthData['raw_par'] ?? 0).toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 12))),
                                   ],
                                 )),
                                 const SizedBox(height: 20),

                                 _buildSectionContainer(child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                      _buildSectionTitle("Disease Diagnosis", Colors.redAccent, Icons.biotech),
                                      const SizedBox(height: 15),
                                      _buildInfoTile("Detected", healthData['disease_detected'] ?? "None", Colors.redAccent, Icons.warning_amber_rounded),
                                      const SizedBox(height: 15),
                                      if (data['recommendations'] != null) ...[
                                        _buildRecommendationBlock("Treatment Plan", data['recommendations']?['fertilizer_suggestions'] ?? "None", Icons.medication),
                                        const SizedBox(height: 10),
                                        _buildRecommendationBlock("Field Management", data['recommendations']?['management_recommendations'] ?? "None", Icons.engineering),
                                      ]
                                   ],
                                 )),
                              ]
                          ] else ...[
                              if (!hasSoil) _buildNoDataMessage("Soil Analysis not performed.")
                              else ...[
                                 // --- SOIL DASHBOARD ---
                                 // Nutrient Chart with Values on Top
                                 _buildSectionContainer(child: Column(
                                   children: [
                                     _buildSectionTitle("Nutrient Profile (N-P-K)", Colors.white, Icons.bar_chart),
                                     const SizedBox(height: 20),
                                     AspectRatio(
                                       aspectRatio: 1.7,
                                       child: _buildNutrientChart(
                                         (soilData!['raw_n'] ?? 0).toDouble(),
                                         (soilData['raw_p'] ?? 0).toDouble(),
                                         (soilData['raw_k'] ?? 0).toDouble()
                                       ),
                                     ),
                                   ],
                                 )),
                                 const SizedBox(height: 20),
                                 
                                 Row(
                                   children: [
                                     Expanded(child: _buildMiniGauge("Moisture", soilData['raw_moisture'] ?? 0.0, Colors.lightBlueAccent, Icons.water_drop)),
                                     const SizedBox(width: 15),
                                     Expanded(child: _buildMiniGauge("Humidity", soilData['raw_humidity'] ?? 0.0, Colors.orangeAccent, Icons.air)),
                                   ],
                                 ),
                                 const SizedBox(height: 20),
                                 
                                 _buildSectionContainer(child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                      _buildSectionTitle("Soil Profile", Colors.brown.shade300, Icons.terrain),
                                      const SizedBox(height: 15),
                                      _buildInfoTile("Classification", soilData['soil_type'] ?? "Unknown", Colors.brown.shade300, Icons.category),
                                      const SizedBox(height: 15),
                                      _buildRecommendationBlock("Suitable Crops", data['crop_suggestions'] ?? "None", Icons.agriculture),
                                      const SizedBox(height: 10),
                                      if (data['soil_quality_management'] != null)
                                        _buildRecommendationBlock("Fertilizer Plan", data['soil_quality_management']?['recommended_fertilizers'] ?? "None", Icons.science),
                                   ],
                                 )),
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

  // --- WIDGET BUILDERS ---

  Widget _buildToggleBtn(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16)
        ),
        child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ]
      ),
      child: child,
    );
  }

  Widget _buildContainerDivider() {
    return Container(height: 30, width: 1, color: Colors.white24);
  }

  Widget _buildSectionTitle(String title, Color color, IconData icon) {
    return Row(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    ]);
  }

  Widget _buildSimpleStat(String label, String value, Color accent, IconData icon) {
    return Column(children: [
      Icon(icon, color: accent.withOpacity(0.8), size: 28),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)), 
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))
    ]);
  }

  Widget _buildAnimatedStat(String label, String valueStr, Color accent, IconData icon) {
    // Extract number from string if possible for animation
    final numValue = double.tryParse(valueStr.replaceAll(RegExp(r'[^0-9.]'), ''));
    final suffix = valueStr.replaceAll(RegExp(r'[0-9.]'), '').trim();

    return Column(children: [
      Icon(icon, color: accent.withOpacity(0.8), size: 28),
      const SizedBox(height: 4),
      if (numValue != null)
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: numValue),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutExpo,
          builder: (context, value, child) {
            return Text("${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} $suffix", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
          },
        )
      else
        Text(valueStr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))
    ]);
  }

  Widget _buildInfoTile(String title, String value, Color color, IconData icon, {bool isMain = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: isMain ? color : Colors.white10, width: isMain ? 1.5 : 1),
        boxShadow: isMain ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)] : []
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGradientGauge(double value, List<Color> colors) {
    return SizedBox(
      height: 100,
      width: 100,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value / 100),
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut,
        builder: (context, val, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: val, 
                strokeWidth: 10, 
                valueColor: AlwaysStoppedAnimation(colors.last), 
                backgroundColor: Colors.grey[800]
              ),
              Center(child: Text("${(val * 100).toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22))),
            ],
          );
        }
      ),
    );
  }

  Widget _buildGauge(double value, Color color) {
    return _buildGradientGauge(value, [color, color]);
  }

  Widget _buildMiniGauge(String label, double value, Color color, IconData icon) {
    return _buildSectionContainer(
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 16), 
            const SizedBox(width: 4), 
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 60, width: 60,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value / 100),
              duration: const Duration(milliseconds: 1500),
              builder: (context, val, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(value: val, strokeWidth: 6, color: color, backgroundColor: Colors.grey[800]),
                    Center(child: Text("${(val * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14))),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChart(double n, double p, double k) {
    // Dynamic Max calculation to prevent cutoff
    double maxVal = [n, p, k].reduce(max);
    double chartMax = maxVal > 100 ? maxVal * 1.2 : 100;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutExpo,
      builder: (context, animValue, child) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartMax,
            barTouchData: BarTouchData(
              enabled: false, 
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.transparent, // Reverted for version 0.66.2
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    rod.toY.toInt().toString(),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    const style = TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 14);
                    switch(val.toInt()) {
                      case 0: return const Text("N", style: style);
                      case 1: return const Text("P", style: style);
                      case 2: return const Text("K", style: style);
                    }
                    return const Text("");
                  }
                )
              ),
              // SHOW LEFT AXIS FOR SCALE
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, 
                  reservedSize: 40, 
                  getTitlesWidget: (val, meta) => Text(
                    val.toInt().toString(), 
                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                  )
                )
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            // SHOW GRID LINES
            gridData: FlGridData(
              show: true, 
              drawVerticalLine: false, 
              getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey[800]!, strokeWidth: 1)
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0, 
                barRods: [BarChartRodData(toY: n * animValue, color: _accentGreen, width: 20, borderRadius: BorderRadius.circular(4))],
                showingTooltipIndicators: [0], 
              ),
              BarChartGroupData(
                x: 1, 
                barRods: [BarChartRodData(toY: p * animValue, color: Colors.orangeAccent, width: 20, borderRadius: BorderRadius.circular(4))],
                showingTooltipIndicators: [0],
              ),
              BarChartGroupData(
                x: 2, 
                barRods: [BarChartRodData(toY: k * animValue, color: Colors.purpleAccent, width: 20, borderRadius: BorderRadius.circular(4))],
                showingTooltipIndicators: [0],
              ),
            ],
          )
        );
      }
    );
  }

  Widget _buildParIndicator(double val) {
    double percent = (val / 1500).clamp(0.0, 1.0);
    return Column(
      children: [
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6), 
            gradient: const LinearGradient(colors: [Colors.redAccent, Colors.yellowAccent, Colors.greenAccent]),
            boxShadow: [BoxShadow(color: Colors.yellowAccent.withOpacity(0.3), blurRadius: 8)]
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment(percent * 2 - 1, 0), 
                child: Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(2))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [Text("Low", style: TextStyle(fontSize: 12, color: Colors.grey)), Text("High", style: TextStyle(fontSize: 12, color: Colors.grey))],
        )
      ],
    );
  }

  Widget _buildRecommendationBlock(String title, String content, IconData icon) {
    return Container(
      width: double.infinity, 
      padding: const EdgeInsets.all(12), 
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)), 
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: _accentGreen),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: _accentGreen, fontSize: 16)),
        ]),
        const SizedBox(height: 8), 
        Text(content, style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.4))
      ])
    );
  }

  Widget _buildNoDataMessage(String msg) {
    return _buildSectionContainer(
      child: Center(
        child: Column(
          children: [const Icon(Icons.info_outline, color: Colors.grey, size: 40), const SizedBox(height: 10), Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 14))],
        ),
      )
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains("optimal") || status.contains("healthy")) return _accentGreen;
    if (status.contains("critical") || status.contains("stressed") || status.contains("infected")) return Colors.redAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Added this to make map visible behind AppBar
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5), // Changed to 50% transparent black
        elevation: 0,
        title: const Text('Field Manager', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.cloud_sync, color: Colors.white), tooltip: 'Process Field', onPressed: _showSaveFieldDialog),
          IconButton(icon: const Icon(Icons.folder_shared, color: Colors.white), tooltip: 'Load Report', onPressed: _showLoadDialog),
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
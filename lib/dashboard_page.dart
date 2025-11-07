import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import for making API calls
import 'dart:convert'; // Import for handling JSON data

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- State for Rainfall Prediction ---
  String _predictionResult = "Prediction will show here.";
  bool _isLoadingPrediction = false;
  final TextEditingController _tempController = TextEditingController();

  // --- NEW: State for Soil Suggestions ---
  String _soilResult = "Suggestions will show here.";
  bool _isLoadingSoil = false;
  final TextEditingController _soilController = TextEditingController();

  // --- Function 1: Get prediction from your Python server ---
  Future<void> _getPrediction(String temperature) async {
    if (temperature.isEmpty) {
      setState(() {
        _predictionResult = "Please enter a temperature.";
      });
      return;
    }

    setState(() {
      _isLoadingPrediction = true;
      _predictionResult = "Getting prediction...";
    });

    try {
      // Use your computer's IP address
      final url = Uri.parse('http://192.168.0.158:5000/predict');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'temperature': temperature}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _predictionResult =
              "Predicted Season: ${data['predicted_season']}\n"
              "Predicted Rainfall: ${data['predicted_rainfall']} mm";
        });
      } else {
        setState(() {
          _predictionResult = "Error from server: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _predictionResult = "Error: Could not connect to the server.\n- Is the Python server running?\n- Is your phone on the same Wi-Fi?";
      });
    } finally {
      setState(() {
        _isLoadingPrediction = false;
      });
    }
  }

  // --- NEW: Function 2: Get soil suggestions ---
  Future<void> _getSoilSuggestions(String soilType) async {
    if (soilType.isEmpty) {
      setState(() {
        _soilResult = "Please enter a soil type (e.g., Sandy soil, Red soil).";
      });
      return;
    }

    setState(() {
      _isLoadingSoil = true;
      _soilResult = "Getting suggestions...";
    });

    try {
      // Use the same IP address as your rainfall model
      final url = Uri.parse('http://192.168.0.158:5000/soil_info'); // <-- Use your PC's IP

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'soil_type': soilType}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Format the lists into clean strings
        final String crops = (data['crop_suggestions'] as List).join(', ');
        final String fertilizers = (data['fertilizer_suggestions'] as List).join(', ');

        setState(() {
          _soilResult = """
Recommended Crops:
$crops

Recommended Fertilizers:
$fertilizers

--- Average Soil Conditions ---
Humidity: ${data['avg_humidity']}%
Moisture: ${data['avg_moisture']}%
Nitrogen: ${data['avg_nitrogen']} kg/ha
Potassium: ${data['avg_potassium']} kg/ha
Phosphorous: ${data['avg_phosphorous']} kg/ha
""";
        });
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        setState(() {
          _soilResult = "Error: ${error['error']}";
        });
      }
    } catch (e) {
      setState(() {
        _soilResult = "Error: Could not connect to the server.";
      });
    } finally {
      setState(() {
        _isLoadingSoil = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose of both controllers
    _tempController.dispose();
    _soilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriDrone Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Card 1: Rainfall & Season Prediction ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Rainfall & Season Prediction",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tempController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Enter Current Temperature (°C)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.thermostat),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _isLoadingPrediction ? null : () => _getPrediction(_tempController.text),
                      child: _isLoadingPrediction
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                            )
                          : const Text('Get Prediction'),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _predictionResult,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24), // Spacer between cards

            // --- NEW: Card 2: Soil & Crop Suggestions ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Soil & Crop Suggestions",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _soilController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Soil Type',
                        hintText: 'e.g., Sandy soil, Red soil...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.grass),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _isLoadingSoil ? null : () => _getSoilSuggestions(_soilController.text),
                      child: _isLoadingSoil
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                            )
                          : const Text('Get Suggestions'),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _soilResult,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // You can add your other original dashboard cards here
          ],
        ),
      ),
    );
  }
}
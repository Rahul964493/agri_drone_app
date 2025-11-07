import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making API calls
import 'dart:convert'; // For handling JSON data
import 'package:image_picker/image_picker.dart'; // For picking videos
// For File operations

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
            // Card 1: Rainfall & Season Prediction
            _RainfallPredictionCard(),
            
            const SizedBox(height: 24), // Spacer

            // Card 2: Manual Soil & Crop Suggestions
            _SoilSuggestionCard(),
            
            const SizedBox(height: 24), // Spacer

            // Card 3: Detect Soil from Video
            _SoilVideoCard(),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET 1: RAINFALL PREDICTION CARD ---

class _RainfallPredictionCard extends StatefulWidget {
  @override
  _RainfallPredictionCardState createState() => _RainfallPredictionCardState();
}

class _RainfallPredictionCardState extends State<_RainfallPredictionCard> {
  String _predictionResult = "Prediction will show here.";
  bool _isLoading = false;
  final TextEditingController _tempController = TextEditingController();

  Future<void> _getPrediction(String temperature) async {
    if (temperature.isEmpty) {
      setState(() {
        _predictionResult = "Please enter a temperature.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = "Getting prediction...";
    });

    try {
      final url = Uri.parse('http://192.168.0.158:5000/predict'); // Your IP

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
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tempController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              onPressed: _isLoading ? null : () => _getPrediction(_tempController.text),
              child: _isLoading
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
    );
  }
}

// --- WIDGET 2: MANUAL SOIL SUGGESTION CARD ---

class _SoilSuggestionCard extends StatefulWidget {
  @override
  _SoilSuggestionCardState createState() => _SoilSuggestionCardState();
}

class _SoilSuggestionCardState extends State<_SoilSuggestionCard> {
  bool _isLoading = false;
  String _soilResult = "Suggestions will show here.";
  final TextEditingController _soilController = TextEditingController();

  Future<void> _getSoilSuggestions(String soilType) async {
    if (soilType.isEmpty) {
      setState(() {
        _soilResult = "Please enter a soil type (e.g., Sandy soil, Red soil).";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _soilResult = "Getting suggestions...";
    });

    try {
      final url = Uri.parse('http://192.168.0.158:5000/soil_info'); // Your IP

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({'soil_type': soilType}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

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
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _soilController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
              onPressed: _isLoading ? null : () => _getSoilSuggestions(_soilController.text),
              child: _isLoading
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
    );
  }
}

// --- WIDGET 3: SOIL DETECTION FROM VIDEO CARD ---

class _SoilVideoCard extends StatefulWidget {
  @override
  _SoilVideoCardState createState() => _SoilVideoCardState();
}

class _SoilVideoCardState extends State<_SoilVideoCard> {
  bool _isLoading = false;
  String _videoResult = "Upload a video to get suggestions.";
  XFile? _videoFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    try {
      final XFile? selectedVideo = await _picker.pickVideo(source: ImageSource.gallery);
      if (selectedVideo != null) {
        setState(() {
          _videoFile = selectedVideo;
          _videoResult = "Video selected: ${selectedVideo.name.split('/').last}\n\nReady to analyze.";
        });
      }
    } catch (e) {
      setState(() {
        _videoResult = "Error picking video: $e";
      });
    }
  }

  Future<void> _uploadAndDetect() async {
    if (_videoFile == null) {
      setState(() {
        _videoResult = "Please select a video first.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _videoResult = "Uploading and analyzing video...";
    });

    try {
      final url = Uri.parse('http://192.168.0.158:5000/detect_soil_video'); // Your IP

      var request = http.MultipartRequest('POST', url);
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          _videoFile!.path,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final String crops = (data['crop_suggestions'] as List).join(', ');
        final String fertilizers = (data['fertilizer_suggestions'] as List).join(', ');

        setState(() {
          _videoResult = """
Detected Soil: ${data['soil_type']}

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
          _videoResult = "Error: ${error['error']}";
        });
      }
    } catch (e) {
      setState(() {
        _videoResult = "Error: Could not connect to the server. $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Detect Soil from Video",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text("Select Video from Gallery"),
              onPressed: _pickVideo,
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: (_isLoading || _videoFile == null) ? null : _uploadAndDetect,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Text('Analyze Soil'),
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
                _videoResult,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
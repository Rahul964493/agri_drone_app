import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making API calls
import 'dart:convert'; // For handling JSON data
import 'package:image_picker/image_picker.dart'; // For picking videos
// Required for File operations
import 'dart:typed_data'; // REQUIRED: For handling image data (Uint8List) - MUST BE AT TOP

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriDrone Dashboard'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
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

            const SizedBox(height: 24), // Spacer

            // Card 4: Detect Disease from Video
            _DiseaseVideoCard(),

            const SizedBox(height: 24), // Spacer

            // Card 5: Crop Health Monitor
            _CropHealthMonitorCard(), 
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
      setState(() => _predictionResult = "Please enter a temperature.");
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = "Getting prediction...";
    });

    try {
      // IMPORTANT: Check this IP matches your server!
      final url = Uri.parse('http://192.168.0.217:5000/predict'); 

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
        setState(() => _predictionResult = "Error from server: ${response.body}");
      }
    } catch (e) {
      setState(() => _predictionResult = "Error: Could not connect to server.");
    } finally {
      setState(() => _isLoading = false);
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
            const Text("Rainfall & Season Prediction", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _tempController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Enter Temperature (°C)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.thermostat)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _getPrediction(_tempController.text),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Get Prediction'),
            ),
            const SizedBox(height: 20),
            Text(_predictionResult, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
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
      setState(() => _soilResult = "Please enter a soil type.");
      return;
    }

    setState(() {
      _isLoading = true;
      _soilResult = "Getting suggestions...";
    });

    try {
      final url = Uri.parse('http://192.168.0.217:5000/soil_info'); 

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
          _soilResult = "Crops: $crops\n\nFertilizers: $fertilizers\n\nNitrogen: ${data['avg_nitrogen']} | Phosphorus: ${data['avg_phosphorous']}";
        });
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        setState(() => _soilResult = "Error: ${error['error']}");
      }
    } catch (e) {
      setState(() => _soilResult = "Error: Could not connect to server.");
    } finally {
      setState(() => _isLoading = false);
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
            const Text("Soil & Crop Suggestions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _soilController,
              decoration: const InputDecoration(labelText: 'Enter Soil Type', border: OutlineInputBorder(), prefixIcon: Icon(Icons.grass)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _getSoilSuggestions(_soilController.text),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Get Suggestions'),
            ),
            const SizedBox(height: 20),
            Text(_soilResult, style: const TextStyle(fontSize: 14)),
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
          _videoResult = "Video selected: ${selectedVideo.name.split('/').last}\nReady to analyze.";
        });
      }
    } catch (e) {
      setState(() => _videoResult = "Error picking video: $e");
    }
  }

  Future<void> _uploadAndDetect() async {
    if (_videoFile == null) return;

    setState(() {
      _isLoading = true;
      _videoResult = "Uploading and analyzing video...";
    });

    try {
      final url = Uri.parse('http://192.168.0.217:5000/detect_soil_video');
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('video', _videoFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String crops = (data['crop_suggestions'] as List).join(', ');
        setState(() {
          _videoResult = "Detected Soil: ${data['soil_type']}\n\nRecommended Crops: $crops";
        });
      } else {
        setState(() => _videoResult = "Error: ${json.decode(response.body)['error']}");
      }
    } catch (e) {
      setState(() => _videoResult = "Error: Connection failed.");
    } finally {
      setState(() => _isLoading = false);
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
            const Text("Detect Soil from Video", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text("Select Video"),
              onPressed: _pickVideo,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_isLoading || _videoFile == null) ? null : _uploadAndDetect,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Analyze Soil'),
            ),
            const SizedBox(height: 20),
            Text(_videoResult, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET 4: DISEASE DETECTION CARD ---

class _DiseaseVideoCard extends StatefulWidget {
  @override
  _DiseaseVideoCardState createState() => _DiseaseVideoCardState();
}

class _DiseaseVideoCardState extends State<_DiseaseVideoCard> {
  bool _isLoading = false;
  String _result = "Upload a leaf video to detect disease.";
  XFile? _videoFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    try {
      final XFile? selected = await _picker.pickVideo(source: ImageSource.gallery);
      if (selected != null) {
        setState(() {
          _videoFile = selected;
          _result = "Selected: ${selected.name.split('/').last}\nReady to diagnose.";
        });
      }
    } catch (e) {
      setState(() => _result = "Error: $e");
    }
  }

  Future<void> _analyze() async {
    if (_videoFile == null) return;

    setState(() {
      _isLoading = true;
      _result = "Scanning for diseases...";
    });

    try {
      final url = Uri.parse('http://192.168.0.217:5000/detect_disease_video'); 
      var request = http.MultipartRequest('POST', url);
      request.files.add(await http.MultipartFile.fromPath('video', _videoFile!.path));

      var streamedResponse = await request.send();
      var res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        setState(() {
          _result = "⚠️ DETECTED: ${data['detected_disease']}\n\nRx: ${data['recommendation']}";
        });
      } else {
        setState(() => _result = "Error: ${res.body}");
      }
    } catch (e) {
      setState(() => _result = "Connection Error. Check IP/Server.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Crop Disease Doctor", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.video_camera_back, color: Colors.red), 
              label: const Text("Select Leaf Video", style: TextStyle(color: Colors.red)), 
              onPressed: _pickVideo
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: (_isLoading || _videoFile == null) ? null : _analyze,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Diagnose Disease"),
            ),
            const SizedBox(height: 16),
            Text(_result, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET 5: CROP HEALTH MONITOR (PAR + NDVI) ---

class _CropHealthMonitorCard extends StatefulWidget {
  @override
  _CropHealthMonitorCardState createState() => _CropHealthMonitorCardState();
}

class _CropHealthMonitorCardState extends State<_CropHealthMonitorCard> {
  bool _isLoading = false;
  String _resultText = "Enter PAR value & Upload NDVI Video.";
  XFile? _videoFile;
  final TextEditingController _parController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  // This variable requires dart:typed_data (now correctly imported at the top)
  Uint8List? _resultImageBytes; 

  Future<void> _pickVideo() async {
    final XFile? selected = await _picker.pickVideo(source: ImageSource.gallery);
    if (selected != null) {
      setState(() {
        _videoFile = selected;
        _resultText = "Video Selected: ${selected.name.split('/').last}\nNow click Analyze.";
      });
    }
  }

  Future<void> _analyzeHealth() async {
    if (_videoFile == null || _parController.text.isEmpty) {
      setState(() => _resultText = "Please enter PAR value and select a video.");
      return;
    }

    setState(() { _isLoading = true; _resultText = "Processing Rules..."; _resultImageBytes = null; });

    try {
      final url = Uri.parse('http://192.168.0.217:5000/analyze_crop_health'); // CHECK IP
      var request = http.MultipartRequest('POST', url);
      
      request.files.add(await http.MultipartFile.fromPath('video', _videoFile!.path));
      request.fields['par_value'] = _parController.text;

      var streamedResponse = await request.send();
      var res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200) {
        var data = json.decode(res.body);
        
        String base64Image = data['health_map'];
        Uint8List bytes = base64Decode(base64Image);

        setState(() {
          _resultImageBytes = bytes;
          _resultText = """
Diagnosis: ${data['diagnosis']}
PAR Condition: ${data['par_status']}
Reliability: ${data['reliability']}
""";
        });
      } else {
        setState(() => _resultText = "Error: ${res.body}");
      }
    } catch (e) {
      setState(() => _resultText = "Connection Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("NDVI & PAR Health Monitor", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 16),
            
            TextField(
              controller: _parController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Current PAR Value (µmol)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wb_sunny),
              ),
            ),
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              icon: const Icon(Icons.video_file, color: Colors.blue),
              label: const Text("Select NDVI/Field Video", style: TextStyle(color: Colors.blue)),
              onPressed: _pickVideo
            ),
            const SizedBox(height: 12),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: (_isLoading) ? null : _analyzeHealth,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Analyze Crop Health"),
            ),
            
            const SizedBox(height: 20),
            
            if (_resultImageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_resultImageBytes!, height: 200, fit: BoxFit.cover),
              ),
              
            const SizedBox(height: 12),
            Text(_resultText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
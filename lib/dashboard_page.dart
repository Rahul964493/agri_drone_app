import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import for making API calls
import 'dart:convert'; // Import for handling JSON data

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _predictionResult = "Prediction will show here.";
  bool _isLoading = false;
  final TextEditingController _tempController = TextEditingController();

  // --- Function to get prediction from your Python server ---
  Future<void> _getPrediction(String temperature) async {
    if (temperature.isEmpty) {
      // Show an error if the text field is empty
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
      // IMPORTANT: Replace 'YOUR_COMPUTER_IP_ADDRESS' with your actual IP.
      // Find it using 'ipconfig' on Windows or 'ifconfig' on Mac/Linux.
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
        // Handle server errors
        setState(() {
          _predictionResult = "Error from server: ${response.body}";
        });
      }
    } catch (e) {
      // Handle connection errors
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriDrone Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- The Prediction Card UI ---
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
            ),
            // You can add your other dashboard cards here
          ],
        ),
      ),
    );
  }
} 
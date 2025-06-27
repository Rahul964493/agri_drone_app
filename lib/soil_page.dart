import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

// Data models to hold our analysis results
class SoilAnalysisResult {
  final List<FlSpot> nirSpots;
  final double avgMoisture;
  final double avgOrganicMatter;
  final double avgNitrogen;
  final String estimatedTexture;
  final double estimatedPh;

  SoilAnalysisResult({
    required this.nirSpots,
    required this.avgMoisture,
    required this.avgOrganicMatter,
    required this.avgNitrogen,
    required this.estimatedTexture,
    required this.estimatedPh,
  });
}

class SoilPage extends StatefulWidget {
  const SoilPage({super.key});

  @override
  State<SoilPage> createState() => _SoilPageState();
}

class _SoilPageState extends State<SoilPage> {
  bool _isLoading = false;
  SoilAnalysisResult? _analysisResult;

  Future<void> _pickAndProcessCsv() async {
    setState(() {
      _isLoading = true;
      _analysisResult = null;
    });

    try {
      // 1. Pick the CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        // 2. Read and Parse the CSV
        PlatformFile file = result.files.first;
        final input = File(file.path!).openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter(shouldParseNumbers: true))
            .toList();

        // Remove header row
        fields.removeAt(0);
        
        // 3. Process Data and Simulate Analysis
        final List<FlSpot> nirSpots = [];
        for (var i = 0; i < fields.length; i++) {
            // Assuming CSV format is: Sample,NIR
            final row = fields[i];
            nirSpots.add(FlSpot(row[0].toDouble(), row[1].toDouble()));
        }

        // ** SIMULATION LOGIC **
        // In a real app, you would pass the NIR values to a machine learning model.
        // Here, we simulate the results with some randomness for demonstration.
        final random = Random();
        final double avgMoisture = 15.0 + random.nextDouble() * 10; // 15-25%
        final double avgOrganicMatter = 2.0 + random.nextDouble() * 3; // 2-5%
        final double avgNitrogen = 20.0 + random.nextDouble() * 15; // 20-35 ppm
        final String estimatedTexture = ['Clay Loam', 'Sandy Loam', 'Silt Loam'][random.nextInt(3)];
        final double estimatedPh = 6.0 + random.nextDouble() * 1.5; // 6.0-7.5

        setState(() {
          _analysisResult = SoilAnalysisResult(
            nirSpots: nirSpots,
            avgMoisture: avgMoisture,
            avgOrganicMatter: avgOrganicMatter,
            avgNitrogen: avgNitrogen,
            estimatedTexture: estimatedTexture,
            estimatedPh: estimatedPh,
          );
        });

      }
    } catch (e) {
      // Handle potential errors, e.g., file format is wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing file: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Nutrient Analysis'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _analysisResult == null
                ? ElevatedButton.icon(
                    onPressed: _pickAndProcessCsv,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Soil NIR Data (CSV)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  )
                : _buildResultsView(),
      ),
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Analysis Results',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Displaying key metrics in a grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildMetricCard('Avg. Moisture', '${_analysisResult!.avgMoisture.toStringAsFixed(2)}%'),
              _buildMetricCard('Organic Matter', '${_analysisResult!.avgOrganicMatter.toStringAsFixed(2)}%'),
              _buildMetricCard('Nitrogen (N)', '${_analysisResult!.avgNitrogen.toStringAsFixed(2)} ppm'),
              _buildMetricCard('Est. pH', _analysisResult!.estimatedPh.toStringAsFixed(2)),
              _buildMetricCard('Est. Texture', _analysisResult!.estimatedTexture, isWide: true),
            ],
          ),
          const SizedBox(height: 32),
          // Displaying the graph
          Text(
            'Continuous NIR Values',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _analysisResult!.nirSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
           const SizedBox(height: 20),
           ElevatedButton(onPressed: (){
            setState(() {
              _analysisResult = null;
            });
           }, child: const Text("Analyze New File"))
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, {bool isWide = false}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, color: Colors.lightGreenAccent),
            ),
          ],
        ),
      ),
    );
  }
}
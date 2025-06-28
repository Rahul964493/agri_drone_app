import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

// 1. DATA MODEL for Crop Analysis Results
class CropAnalysisResult {
  final double avgNDVI;
  final double avgGNDVI;
  final double avgSAVI;
  final double avgMSAVI;
  final List<FlSpot> redSpots;
  final List<FlSpot> greenSpots;
  final List<FlSpot> nirSpots;
  final List<FlSpot> parSpots;

  CropAnalysisResult({
    required this.avgNDVI,
    required this.avgGNDVI,
    required this.avgSAVI,
    required this.avgMSAVI,
    required this.redSpots,
    required this.greenSpots,
    required this.nirSpots,
    required this.parSpots,
  });
}

class CropPage extends StatefulWidget {
  const CropPage({super.key});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  bool _isLoading = false;
  CropAnalysisResult? _analysisResult;

  // 2. PROCESSING LOGIC with real calculations
  Future<void> _pickAndProcessCsv() async {
    setState(() => _isLoading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: kIsWeb,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        List<List<dynamic>> fields;

        if (kIsWeb) {
          final List<int> fileBytes = file.bytes!;
          final String csvString = utf8.decode(fileBytes);
          fields = const CsvToListConverter(shouldParseNumbers: true, eol: '\n').convert(csvString);
        } else {
          final input = File(file.path!).openRead();
          fields = await input.transform(utf8.decoder).transform(const CsvToListConverter(shouldParseNumbers: true)).toList();
        }

        if (fields.length < 2) throw Exception("CSV file must have a header and at least one data row.");
        
        final header = fields.removeAt(0).map((e) => e.toString().trim().toUpperCase()).toList();
        // Verify header columns
        if (!header.contains(['RED', 'GREEN', 'NIR', 'PAR'])) {
          throw Exception("CSV file must contain 'Red', 'Green', 'NIR', and 'PAR' columns.");
        }

        // Get column indices
        final redIndex = header.indexOf('RED');
        final greenIndex = header.indexOf('GREEN');
        final nirIndex = header.indexOf('NIR');
        final parIndex = header.indexOf('PAR');
        final sampleIndex = header.indexOf('SAMPLE');

        final List<double> ndviValues = [];
        final List<double> gndviValues = [];
        final List<double> saviValues = [];
        final List<double> msaviValues = [];

        final List<FlSpot> redSpots = [];
        final List<FlSpot> greenSpots = [];
        final List<FlSpot> nirSpots = [];
        final List<FlSpot> parSpots = [];

        for (var i = 0; i < fields.length; i++) {
          final row = fields[i];
          double sample = row[sampleIndex].toDouble();
          double red = row[redIndex].toDouble();
          double green = row[greenIndex].toDouble();
          double nir = row[nirIndex].toDouble();
          double par = row[parIndex].toDouble();

          // Add spots for graphs
          redSpots.add(FlSpot(sample, red));
          greenSpots.add(FlSpot(sample, green));
          nirSpots.add(FlSpot(sample, nir));
          parSpots.add(FlSpot(sample, par));

          // ** VEGETATION INDEX CALCULATIONS **
          if ((nir + red) > 0) ndviValues.add((nir - red) / (nir + red));
          if ((nir + green) > 0) gndviValues.add((nir - green) / (nir + green));
          
          const double L = 0.5; // Soil brightness factor for SAVI
          if ((nir + red + L) > 0) saviValues.add(((nir - red) / (nir + red + L)) * (1 + L));
          
          msaviValues.add((2 * nir + 1 - sqrt(pow(2 * nir + 1, 2) - 8 * (nir - red))) / 2);
        }

        double avg(List<double> v) => v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;

        setState(() {
          _analysisResult = CropAnalysisResult(
            avgNDVI: avg(ndviValues),
            avgGNDVI: avg(gndviValues),
            avgSAVI: avg(saviValues),
            avgMSAVI: avg(msaviValues),
            redSpots: redSpots,
            greenSpots: greenSpots,
            nirSpots: nirSpots,
            parSpots: parSpots,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Health Monitoring'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _analysisResult == null
                ? _buildUploadUI()
                : _buildResultsView(),
      ),
    );
  }

  Widget _buildUploadUI() {
    return Center(
      key: const ValueKey('upload'),
      child: InkWell(
        onTap: _pickAndProcessCsv,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade600, style: BorderStyle.solid, width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grass_outlined, size: 60, color: Colors.grey.shade500),
              const SizedBox(height: 16),
              Text('Upload Crop Data', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Tap to select a .csv file', style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultsView() {
    final results = _analysisResult!;
    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vegetation Index Analysis',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Key metrics
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              _MetricCard(title: 'Avg. NDVI', value: results.avgNDVI.toStringAsFixed(3), description: 'Overall plant health'),
              _MetricCard(title: 'Avg. GNDVI', value: results.avgGNDVI.toStringAsFixed(3), description: 'Nitrogen content'),
              _MetricCard(title: 'Avg. SAVI', value: results.avgSAVI.toStringAsFixed(3), description: 'Corrects for soil brightness'),
              _MetricCard(title: 'Avg. MSAVI', value: results.avgMSAVI.toStringAsFixed(3), description: 'Improved SAVI for sparse vegetation'),
            ],
          ),
          const SizedBox(height: 24),

          // Spectral Bands Graph
          _buildMultiLineChart(
            title: "Spectral Reflectance",
            lines: {
              'NIR': ChartLine(spots: results.nirSpots, color: Colors.lightGreenAccent),
              'Green': ChartLine(spots: results.greenSpots, color: Colors.green),
              'Red': ChartLine(spots: results.redSpots, color: Colors.redAccent),
            }
          ),

          const SizedBox(height: 24),
          
          // PAR Graph
          _buildMultiLineChart(
            title: "Photosynthetically Active Radiation (PAR)",
             lines: {
              'PAR': ChartLine(spots: results.parSpots, color: Colors.amber),
            }
          ),

          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => setState(() => _analysisResult = null), child: const Text("Analyze New File")),
        ],
      ),
    );
  }

   Widget _MetricCard({required String title, required String value, required String description}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green.shade300)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiLineChart({required String title, required Map<String, ChartLine> lines}) {
    return Card(
       elevation: 4,
       child: Padding(
         padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
         child: Column(
           children: [
             Text(title, style: Theme.of(context).textTheme.titleLarge),
             const SizedBox(height: 20),
             SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true, drawVerticalLine: true),
                    titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: lines.entries.map((entry) => LineChartBarData(
                      spots: entry.value.spots,
                      isCurved: true,
                      color: entry.value.color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    )).toList(),
                    // Legend
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final line = lines.entries.toList()[spot.barIndex];
                            return LineTooltipItem(
                              '${line.key}: ${spot.y.toStringAsFixed(2)}',
                              TextStyle(color: line.value.color, fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
           ],
         ),
       ),
    );
  }
}

class ChartLine {
  final List<FlSpot> spots;
  final Color color;
  ChartLine({required this.spots, required this.color});
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

// 1. EXPANDED DATA MODEL for a more detailed analysis
class SoilAnalysisResult {
  final List<FlSpot> nirSpots;
  final double minNir;
  final double maxNir;
  final double avgMoisture;
  final double avgOrganicMatter;
  final double avgNitrogen;
  final Map<String, double> textureComposition; // e.g., {'Clay': 40, 'Silt': 35, 'Sand': 25}
  final double estimatedPh;
  final String recommendations;

  SoilAnalysisResult({
    required this.nirSpots,
    required this.minNir,
    required this.maxNir,
    required this.avgMoisture,
    required this.avgOrganicMatter,
    required this.avgNitrogen,
    required this.textureComposition,
    required this.estimatedPh,
    required this.recommendations,
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

  // 2. UPDATED PROCESSING LOGIC with richer simulation
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
        fields.removeAt(0);

        final List<FlSpot> nirSpots = [];
        final List<double> nirValues = [];
        for (var i = 0; i < fields.length; i++) {
          final row = fields[i];
          if (row.length >= 2) {
            double sample = row[0].toDouble();
            double nir = row[1].toDouble();
            nirSpots.add(FlSpot(sample, nir));
            nirValues.add(nir);
          }
        }
        if (nirValues.isEmpty) throw Exception("No valid NIR data found in the file.");

        // ** RICHER SIMULATION LOGIC **
        final random = Random();
        double avgMoisture = 15.0 + random.nextDouble() * 10;
        double avgOrganicMatter = 2.0 + random.nextDouble() * 3;
        double avgNitrogen = 20.0 + random.nextDouble() * 15;
        double estimatedPh = 6.0 + random.nextDouble() * 1.5;

        // Simulate texture composition
        double clay = 20 + random.nextDouble() * 20;
        double silt = 20 + random.nextDouble() * 20;
        double sand = 100 - clay - silt;
        Map<String, double> texture = {'Clay': clay, 'Silt': silt, 'Sand': sand};

        // Simulate recommendations
        String recommendations = "Soil appears balanced. ";
        if (estimatedPh < 6.5) recommendations += "Consider applying lime to raise pH. ";
        if (avgMoisture < 18.0) recommendations += "Moisture levels are low; monitor irrigation needs. ";
        if (avgOrganicMatter < 2.5) recommendations += "Consider adding compost to improve organic matter.";


        setState(() {
          _analysisResult = SoilAnalysisResult(
            nirSpots: nirSpots,
            minNir: nirValues.reduce(min),
            maxNir: nirValues.reduce(max),
            avgMoisture: avgMoisture,
            avgOrganicMatter: avgOrganicMatter,
            avgNitrogen: avgNitrogen,
            textureComposition: texture,
            estimatedPh: estimatedPh,
            recommendations: recommendations,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Nutrient Analysis'),
      ),
      // 3. ADDED ANIMATED SWITCHER for smooth transitions
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

  // 4. NEW UPLOAD WIDGET for better UI
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
              Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.grey.shade500),
              const SizedBox(height: 16),
              Text('Upload Soil NIR Data', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Tap to select a .csv file', style: TextStyle(color: Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }

  // 5. REVAMPED RESULTS VIEW
  Widget _buildResultsView() {
    final results = _analysisResult!;
    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Analysis Summary", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.greenAccent)),
                  const SizedBox(height: 12),
                  Text("Based on the provided NIR data, here is a summary of the soil's key characteristics and our recommendations.", style: Theme.of(context).textTheme.bodyMedium),
                   const SizedBox(height: 16),
                   Text("Recommendations", style: Theme.of(context).textTheme.titleMedium),
                   const SizedBox(height: 8),
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Icon(Icons.biotech_outlined, size: 18, color: Colors.cyanAccent),
                       const SizedBox(width: 8),
                       Expanded(child: Text(results.recommendations)),
                     ],
                   ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Metric Gauges
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _MetricCard(title: 'Avg. Moisture', value: "${results.avgMoisture.toStringAsFixed(1)}%", icon: Icons.water_drop_outlined, color: Colors.blue),
              _MetricCard(title: 'Organic Matter', value: "${results.avgOrganicMatter.toStringAsFixed(1)}%", icon: Icons.eco_outlined, color: Colors.brown.shade300),
              _MetricCard(title: 'Nitrogen (N)', value: "${results.avgNitrogen.toStringAsFixed(1)} ppm", icon: Icons.grass_outlined, color: Colors.green),
              _MetricCard(title: 'Est. pH', value: results.estimatedPh.toStringAsFixed(1), icon: Icons.science_outlined, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 24),

          // Texture Pie Chart Card
          _TexturePieChart(composition: results.textureComposition),

          const SizedBox(height: 24),

          // NIR Line Chart Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  Text("NIR Reflectance Analysis", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                       Text("Min: ${results.minNir.toStringAsFixed(2)}"),
                       Text("Max: ${results.maxNir.toStringAsFixed(2)}"),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(height: 300, child: _buildLineChart(results.nirSpots)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => setState(() => _analysisResult = null), child: const Text("Analyze New File")),
        ],
      ),
    );
  }

  // 6. NEW CUSTOM WIDGET for metrics
  Widget _MetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
  
  // 7. IMPROVED Line Chart
  Widget _buildLineChart(List<FlSpot> spots) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white12, strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Colors.white12, strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
        minX: spots.first.x,
        maxX: spots.last.x,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.green]),
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [Colors.greenAccent.withOpacity(0.3), Colors.green.withOpacity(0.3)]),
            ),
          ),
        ],
      ),
    );
  }
}

// 8. NEW PIE CHART WIDGET
class _TexturePieChart extends StatelessWidget {
  final Map<String, double> composition;
  _TexturePieChart({required this.composition});

  final List<Color> pieColors = const [Colors.brown, Colors.orangeAccent, Colors.blueGrey];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Estimated Soil Texture", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(composition.length, (i) {
                    final entry = composition.entries.elementAt(i);
                    return PieChartSectionData(
                      color: pieColors[i],
                      value: entry.value,
                      title: '${entry.value.toStringAsFixed(0)}%',
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }),
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(composition.length, (i) {
                 final entry = composition.entries.elementAt(i);
                 return Row(children: [
                    Container(width: 16, height: 16, color: pieColors[i]),
                    const SizedBox(width: 8),
                    Text(entry.key)
                 ]);
              })
            )
          ],
        ),
      ),
    );
  }
}
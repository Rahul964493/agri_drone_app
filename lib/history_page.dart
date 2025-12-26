import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'report_viewer.dart';

class HistoryPage extends StatefulWidget {
  final String filterMode; // 'soil' or 'health'
  const HistoryPage({super.key, required this.filterMode});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final String _serverUrl = 'http://192.168.0.217:5000'; 
  List<String> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFields();
  }

  Future<void> _fetchFields() async {
    try {
      final response = await http.get(Uri.parse('$_serverUrl/get_fields'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['fields'];
        setState(() {
          _fields = data.cast<String>();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error connecting: $e"), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _openFieldReport(String fieldName) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))));
    try {
      final response = await http.post(Uri.parse('$_serverUrl/get_field_data'), body: jsonEncode({'field_name': fieldName}));
      Navigator.pop(context); 
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => FieldReportSheet(data: data, initialView: widget.filterMode),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to load report"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = widget.filterMode == 'health' ? const Color(0xFF2979FF) : const Color(0xFF00E676);
    String title = widget.filterMode == 'health' ? "Health Reports" : "Soil Analysis Records";
    IconData icon = widget.filterMode == 'health' ? Icons.monitor_heart_outlined : Icons.grass;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : _fields.isEmpty 
          ? Center(child: Text("No records found.", style: TextStyle(color: Colors.grey[600])))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _fields.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05))
                  ),
                  child: ListTile(
                    leading: Icon(icon, color: accentColor),
                    title: Text(_fields[index], style: const TextStyle(color: Colors.white, fontSize: 16)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _openFieldReport(_fields[index]),
                  ),
                );
              },
            ),
    );
  }
}
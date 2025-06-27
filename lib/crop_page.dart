import 'package:flutter/material.dart';

class CropPage extends StatelessWidget {
  const CropPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Health Monitoring')),
      body: const Center(
        child: Text('Crop Health Page - Coming in Step 3!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
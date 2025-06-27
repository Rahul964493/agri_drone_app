import 'package:flutter/material.dart';

class SoilPage extends StatelessWidget {
  const SoilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soil Nutrient Analysis')),
      body: const Center(
        child: Text('Soil Analysis Page - Coming in Step 3!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
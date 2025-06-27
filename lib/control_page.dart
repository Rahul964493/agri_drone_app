import 'package:flutter/material.dart';

class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Flight Control')),
      body: const Center(
        child: Text('UAV Control Page - Coming in Step 4!', style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
import 'package:agri_drone_app/control_page.dart'; // We'll create this later
import 'package:flutter/material.dart';


class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriDrone Dashboard'),
        actions: [
          // UAV Status Indicator
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(
              children: [
                const Text('UAV: Connected '),
                Icon(Icons.check_circle, color: Colors.green.shade400, size: 18),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            const Text(
              'Welcome, User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Card Layout
            DashboardCard(
              title: 'Fly Your UAV',
              icon: Icons.flight_takeoff_outlined,
              subtitle: 'Take manual control of your drone.',
              buttonText: 'Start Flying',
              onPressed: () {
                // Navigate to the full-screen UAV Control Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ControlPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            DashboardCard(
              title: 'Manage Crop Fields',
              icon: Icons.map,
              subtitle: 'Map your fields and generate flight paths.',
              buttonText: 'Go to Map',
              onPressed: () {
                // This will be handled by the bottom navigation bar
                // but you could add specific navigation here if needed.
                // For now, we can leave it empty or show a snackbar.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please use the bottom navigation bar.')),
                );
              },
            ),
            const SizedBox(height: 16),
            DashboardCard(
              title: 'Analyze Soil Nutrients',
              icon: Icons.eco_outlined,
              subtitle: 'Upload NIR data to assess soil health.',
              buttonText: 'Analyze Soil',
              onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please use the bottom navigation bar.')),
                );
              },
            ),
            const SizedBox(height: 16),
            DashboardCard(
              title: 'Monitor Crop Health',
              icon: Icons.grass_outlined,
              subtitle: 'Assess crop vigor using vegetation indices.',
              buttonText: 'Monitor Crops',
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please use the bottom navigation bar.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// A reusable card widget for the dashboard
class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const DashboardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 40, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade400)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
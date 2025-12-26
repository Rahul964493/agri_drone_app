import 'package:flutter/material.dart';
import 'map_page.dart';
import 'history_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color darkBg = const Color(0xFF121212);
    final Color accentGreen = const Color(0xFF00E676);
    final Color accentBlue = const Color(0xFF2979FF);
    final Color accentPurple = const Color(0xFFD500F9);
    final Color accentOrange = const Color(0xFFFF9100);

    return Scaffold(
      backgroundColor: darkBg,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A), // Slightly lighter top
              darkBg,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // --- 1. AI HELPER SECTION ---
                Center(
                  child: Column(
                    children: [
                      // Glowing Bot Avatar
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2C2C2C),
                          border: Border.all(color: accentGreen, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accentGreen.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Icon(Icons.smart_toy_outlined, size: 50, color: accentGreen),
                      ),
                      const SizedBox(height: 20),
                      // Greeting Text
                      const Text(
                        "Hii, Farmer!",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "What do you want to do today?",
                        style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // --- 2. NEW SURVEY SECTION ---
                Row(
                  children: [
                    Icon(Icons.add_location_alt_outlined, color: accentGreen, size: 20),
                    const SizedBox(width: 8),
                    Text("START NEW SURVEY", style: TextStyle(color: accentGreen, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    // Option 1: Soil Analysis
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: "Soil Analysis",
                        subtitle: "Check Nutrients\n& Texture",
                        icon: Icons.grass,
                        color: accentGreen,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage(preSelectedAnalysis: "Soil Analysis")));
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Option 2: Crop Health
                    Expanded(
                      child: _buildActionCard(
                        context,
                        title: "Crop Health",
                        subtitle: "Disease & Stress\nMonitoring",
                        icon: Icons.monitor_heart_outlined,
                        color: accentBlue,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPage(preSelectedAnalysis: "Crop Health Monitoring")));
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // --- 3. PREVIOUS RECORDS SECTION ---
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text("PREVIOUS RECORDS", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 20),

                // Option 3: Previous Soil Analysis
                _buildWideListTile(
                  context,
                  title: "Monitor Soil Analysis",
                  subtitle: "View history of soil reports",
                  icon: Icons.terrain,
                  color: accentOrange,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage(filterMode: 'soil')));
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Option 4: Previous Crop Health
                _buildWideListTile(
                  context,
                  title: "Monitor Crop Health",
                  subtitle: "View history of health maps",
                  icon: Icons.health_and_safety,
                  color: accentPurple,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage(filterMode: 'health')));
                  },
                ),
                
                // Bottom padding to ensure scrolling isn't tight
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildActionCard(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF252525), const Color(0xFF1A1A1A)],
          )
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 1)
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.2)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWideListTile(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
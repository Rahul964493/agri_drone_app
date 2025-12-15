import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agri_drone_app/map_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // UPDATED NAME HERE
      title: 'SkyFarm Analytics', 
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        brightness: Brightness.dark, 
        scaffoldBackgroundColor: const Color(0xFF121212), 
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait 3 seconds, then go to MapPage
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MapPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(
          'assets/Splash Screen.jpg', 
          fit: BoxFit.cover, 
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFF0D1117),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.precision_manufacturing, size: 80, color: Color(0xFF00E676)),
                    SizedBox(height: 10),
                    Text(
                      "Image not found:\nassets/Splash Screen.jpg", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white)
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
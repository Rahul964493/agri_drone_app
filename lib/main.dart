import 'package:agri_drone_app/crop_page.dart';
import 'package:agri_drone_app/dashboard_page.dart';
import 'package:agri_drone_app/map_page.dart';
import 'package:agri_drone_app/soil_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      title: 'AgriDrone Monitor',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        brightness: Brightness.dark, // A dark theme often works well for field apps
      ),
      home: const MainAppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  // List of the pages that will be switched by the navigation bar
  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardPage(),
    const MapPage(),
    const SoilPage(),
    const CropPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Field Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco), // Icon for soil
            label: 'Soil Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass), // Icon for crop
            label: 'Crop Health',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Good for 4+ items
        backgroundColor: Colors.black87,
      ),
    );
  }
}
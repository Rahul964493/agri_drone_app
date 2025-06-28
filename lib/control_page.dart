import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  // --- ENHANCED SIMULATED TELEMETRY DATA ---
  double _altitude = 0.0;
  double _speed = 0.0;
  int _batteryLevel = 100;
  int _gpsSignal = 0;
  String _flightStatus = "Landed";
  Timer? _telemetryTimer;

  // New Data Points
  double _homeDistance = 0.0;
  int _flightTimeInSeconds = 0;
  int _rcSignalStrength = 99; // As a percentage
  double _gimbalPitch = 0.0;


  @override
  void initState() {
    super.initState();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), _updateTelemetry);
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }

  // --- SIMULATOR and SDK PLACEHOLDER FUNCTIONS ---

  void _updateTelemetry(Timer timer) {
    // This function simulates live data from the drone
    setState(() {
      _gpsSignal = 8 + Random().nextInt(5);
      
      if (_flightStatus == "Flying") {
        // Simulate flight data changes
        _altitude += (Random().nextDouble() - 0.45); // Fluctuate altitude
        if (_altitude < 0) _altitude = 0;
        
        // Speed changes via joystick, but we can simulate slight drifts
        _speed = max(0, _speed + (Random().nextDouble() - 0.5));
        
        // Update new data points
        _flightTimeInSeconds++;
        _homeDistance += _speed / 3.6; // Rough distance calculation
        _rcSignalStrength = 90 + Random().nextInt(10); // Simulate strong signal
        if(_batteryLevel > 0) _batteryLevel -= 1; // Battery drain
      } else {
         _rcSignalStrength = 99;
      }
    });
    // TODO: In a real app, you would get these values from the drone SDK's listeners.
  }

  void _onTakeOffPressed() {
    setState(() {
      _flightStatus = "Flying";
      _altitude = 10.0;
      // Reset mission stats
      _flightTimeInSeconds = 0;
      _homeDistance = 0.0;
    });
    // TODO: Integrate UAV SDK here. e.g., drone.actions.takeOff();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SDK: Take Off Command Sent")));
  }

  void _onLandPressed() {
    setState(() {
      _flightStatus = "Landed";
      _altitude = 0.0;
      _speed = 0.0;
    });
    // TODO: Integrate UAV SDK here. e.g., drone.actions.land();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SDK: Land Command Sent")));
  }
  
  void _onJoystickMoved(StickDragDetails details) {
    double pitch = -details.y; // Forward/Backward
    double roll = details.x; // Left/Right
    
    // TODO: Integrate UAV SDK here to send roll/pitch data for movement.
    // e.g., drone.controls.setRollPitch(roll, pitch);
    
    if (_flightStatus == "Flying") {
      setState(() {
         _speed = (sqrt(pow(details.x, 2) + pow(details.y, 2)) * 15); // Simulate speed up to 15 m/s
      });
    }
  }

  void _onLeftJoystickMoved(StickDragDetails details) {
      // TODO: Integrate SDK for Altitude/Yaw control
      // e.g., drone.controls.setAltitudeAndYaw(details.y, details.x);
      
      // Simulate gimbal pitch control with the left joystick's vertical axis
      setState(() {
        _gimbalPitch -= details.y * 2; // Move gimbal pitch
        if (_gimbalPitch > 0) _gimbalPitch = 0;
        if (_gimbalPitch < -90) _gimbalPitch = -90;
      });
  }
  
  // Helper to format flight time
  String _formatFlightTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // --- UI BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              color: Colors.grey.shade800,
              child: const Center(
                child: Icon(Icons.videocam_off_outlined, size: 120, color: Colors.black38),
              ),
            ),
            _buildOSD(),
            Positioned(
              top: 120, // Adjusted position to be below new OSD
              right: 15,
              child: Column(
                children: [
                   FloatingActionButton(
                    heroTag: "fab_takeoff",
                    onPressed: _onTakeOffPressed, 
                    backgroundColor: Colors.green.withOpacity(0.8),
                    child: const Icon(Icons.flight_takeoff_outlined)
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: "fab_land",
                    onPressed: _onLandPressed, 
                    backgroundColor: Colors.red.withOpacity(0.8),
                    child: const Icon(Icons.flight_land_outlined)
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0, left: 30, right: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Joystick(
                      mode: JoystickMode.all, 
                      listener: _onLeftJoystickMoved,
                    ),
                    Joystick(
                      mode: JoystickMode.all,
                      listener: _onJoystickMoved,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // REFACTORED OSD Widget with more data
  Widget _buildOSD() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Status indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _flightStatus == "Flying" ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(_flightStatus.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                ),
                Row(
                  children: [
                    _OSDStatusIcon(icon: Icons.satellite_alt, value: '$_gpsSignal'),
                    const SizedBox(width: 12),
                    _OSDStatusIcon(icon: Icons.signal_cellular_alt, value: '$_rcSignalStrength%'),
                    const SizedBox(width: 12),
                    _OSDStatusIcon(icon: _getBatteryIcon(), value: '$_batteryLevel%'),
                  ],
                )
              ],
            ),
          ),
          // Bottom Row: Flight metrics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            color: Colors.black.withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OSDMetric(label: 'ALT', value: '${_altitude.toStringAsFixed(1)}m'),
                _OSDMetric(label: 'H.DIST', value: '${_homeDistance.toStringAsFixed(1)}m'),
                _OSDMetric(label: 'SPD', value: '${_speed.toStringAsFixed(1)}m/s'),
                _OSDMetric(label: 'GIMBAL', value: '${_gimbalPitch.toStringAsFixed(0)}°'),
                _OSDMetric(label: 'TIME', value: _formatFlightTime(_flightTimeInSeconds)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _OSDMetric({required String label, required String value}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'sans-serif'),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(color: Colors.white70)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]
      ),
    );
  }

  Widget _OSDStatusIcon({required IconData icon, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  IconData _getBatteryIcon() {
    if (_batteryLevel > 90) return Icons.battery_full;
    if (_batteryLevel > 70) return Icons.battery_6_bar;
    if (_batteryLevel > 50) return Icons.battery_4_bar;
    if (_batteryLevel > 30) return Icons.battery_2_bar;
    if (_batteryLevel > 10) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }
}
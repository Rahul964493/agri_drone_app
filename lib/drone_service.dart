import 'package:dart_mavlink/mavlink.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class DroneService {
  final parser = MavlinkParser();
  SerialPort? _port;

  // Function to listen for messages and update the UI
  final Function(MavlinkFrame frame) onDataReceived;
  DroneService({required this.onDataReceived});

  void connect() {
    // Find the correct USB device (telemetry radio)
    final availablePorts = SerialPort.availablePorts;
    if (availablePorts.isEmpty) {
      print("No serial ports found.");
      return;
    }
    _port = SerialPort(availablePorts.first);
    if (!_port!.openReadWrite()) {
        print("Failed to open port");
        return;
    }
    
    // Listen for incoming data from the drone
    _port!.reader!.stream.listen((data) {
      parser.parse(data).forEach((frame) {
        // When a complete MAVLink message is parsed, send it to the UI
        onDataReceived(frame);
      });
    });
  }

  void send(MavlinkFrame frame) {
    _port?.write(frame.serialize());
  }

  void takeoff() {
    final command = MavlinkCommandLongMessage(
        targetSystem: 1,
        targetComponent: 1,
        command: MavlinkCommand.MAV_CMD_NAV_TAKEOFF,
        confirmation: 0,
        param1: 0, // pitch
        param2: 0,
        param3: 0,
        param4: 0,
        param5: 0, // latitude
        param6: 0, // longitude
        param7: 10 // altitude in meters
    );
    send(MavlinkFrame.v2(0, 0, command));
    print("Sent Takeoff Command!");
  }

  // You would create similar methods for land(), returnToHome(), etc.
}
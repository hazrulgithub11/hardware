import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key, required this.title});

  final String title;

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  static const platform =
      MethodChannel('com.example.hardwarelab/bluetooth'); // Platform channel
  List<String> _pairedDevices = [];
  List<Map<String, String>> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    _getPairedDevices();
    // Listen for devices found during scan
    platform.setMethodCallHandler((call) async {
      if (call.method == "onDeviceFound") {
        final device = Map<String, String>.from(call.arguments);
        setState(() {
          _availableDevices.add(device);
        });
      }
    });
  }

  // Method to get list of paired Bluetooth devices
  Future<void> _getPairedDevices() async {
    try {
      final List<dynamic> devices =
          await platform.invokeMethod('getPairedDevices');
      setState(() {
        _pairedDevices = devices.cast<String>();
      });
    } on PlatformException catch (e) {
      print("Error getting paired devices: ${e.message}");
    }
  }

  // Method to start scanning for available devices
  Future<void> _startScanning() async {
    try {
      await platform.invokeMethod('startScan');
    } on PlatformException catch (e) {
      print("Error starting scan: ${e.message}");
    }
  }

  // Method to handle device pairing and logging
  Future<void> pairDevice(String address, String name) async {
    try {
      final result =
          await platform.invokeMethod('pairDevice', {'address': address});
      if (result == 'Pairing initiated.') {
        logDevicePairing(name, address);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
    } on PlatformException catch (e) {
      print("Error pairing device: ${e.message}");
    }
  }

  // Method to log device pairing to Firestore
  Future<void> logDevicePairing(String name, String address) async {
    try {
      await FirebaseFirestore.instance.collection('device_pairings').add({
        'name': name,
        'address': address,
        'paired_at': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device logged: $name')),
      );
    } catch (e) {
      print('Error logging device: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _getPairedDevices,
            child: Text('Get Paired Devices'),
          ),
          ElevatedButton(
            onPressed: _startScanning,
            child: Text('Scan for Available Devices'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pairedDevices.length,
              itemBuilder: (context, index) {
                String device = _pairedDevices[index];
                return ListTile(
                  title: Text(device),
                  trailing: IconButton(
                    icon: Icon(Icons.bluetooth),
                    onPressed: () =>
                        pairDevice(device, device), // Pair and log to Firestore
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _availableDevices.length,
              itemBuilder: (context, index) {
                var device = _availableDevices[index];
                return ListTile(
                  title: Text(device['name'] ?? 'Unknown Device'),
                  trailing: IconButton(
                    icon: Icon(Icons.bluetooth),
                    onPressed: () =>
                        pairDevice(device['address']!, device['name']!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

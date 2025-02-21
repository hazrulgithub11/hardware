import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccelerometerPage extends StatefulWidget {
  @override
  _AccelerometerPageState createState() => _AccelerometerPageState();
}

class _AccelerometerPageState extends State<AccelerometerPage> {
  double _x = 0, _y = 0, _z = 0;
  bool _isLoading = true;
  AccelerometerEvent? _lastEvent;
  static const double _threshold = 0.5; // Threshold for changes

  @override
  void initState() {
    super.initState();

    // Start listening to accelerometer events
    accelerometerEvents.listen((AccelerometerEvent event) {
      setState(() {
        _x = event.x;
        _y = event.y;
        _z = event.z;

        // Only store data in Firestore if it exceeds threshold
        if (_lastEvent == null || _shouldUpdate(_lastEvent!, event)) {
          _storeAccelerometerMetadata(event);
        }

        _lastEvent = event;
        _isLoading = false; // Data has been received, stop loading
      });
    });
  }

  // Check if the change is greater than the threshold
  bool _shouldUpdate(AccelerometerEvent oldEvent, AccelerometerEvent newEvent) {
    return (newEvent.x - oldEvent.x).abs() > _threshold ||
        (newEvent.y - oldEvent.y).abs() > _threshold ||
        (newEvent.z - oldEvent.z).abs() > _threshold;
  }

  // Method to store accelerometer data to Firestore
  Future<void> _storeAccelerometerMetadata(AccelerometerEvent event) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final accelerometerData = {
        'x': event.x,
        'y': event.y,
        'z': event.z,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await firestore.collection('accelerometer_data').add(accelerometerData);
      print("Accelerometer metadata stored successfully.");
    } catch (e) {
      print('Error storing metadata in Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Accelerometer')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Accelerometer Metrics:',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  Text('X: $_x', style: TextStyle(fontSize: 24)),
                  Text('Y: $_y', style: TextStyle(fontSize: 24)),
                  Text('Z: $_z', style: TextStyle(fontSize: 24)),
                ],
              ),
            ),
    );
  }
}

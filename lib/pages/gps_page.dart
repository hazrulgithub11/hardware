import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class GPSPage extends StatefulWidget {
  @override
  _GPSPageState createState() => _GPSPageState();
}

class _GPSPageState extends State<GPSPage> {
  LatLng _currentPosition = LatLng(0.0, 0.0); // Initial position set to 0, 0
  bool _isLoading = true;
  MapController _mapController =
      MapController(); // Create a MapController instance

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    PermissionStatus locationPermission = await Permission.location.request();
    if (locationPermission.isGranted) {
      _getCurrentLocation();
    } else {
      print("Location permission denied.");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Store location metadata in Firestore
      _storeLocationMetadata(position);
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _storeLocationMetadata(Position position) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userLocation = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'device': 'Flutter Device',
      };
      await firestore.collection('locations').add(userLocation);
      print("Location metadata stored successfully.");
    } catch (e) {
      print('Error storing metadata in Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS with OpenStreetMap')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController, // Pass the map controller
              options: MapOptions(
                initialCenter: _currentPosition, // Correctly set the map center
                initialZoom: 15, // Set the default zoom level
                minZoom: 0, // Set minimum zoom
                maxZoom: 18, // Set maximum zoom
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition, // Marker position
                      width: 80.0,
                      height: 80.0,
                      child: const Icon(
                        // Use 'child' instead of 'builder'
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

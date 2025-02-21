# HardwareLab

A new Flutter project for accessing various hardware functionalities.

## 2410-ICT602 Lab Work 8

### Accessing The Hardware

This project is a starting point for a Flutter application that focuses on accessing hardware features.

## Initialization Steps

### 1. Camera Initialization

- Add the camera dependency in `pubspec.yaml`:

  ```yaml
  dependencies:
    camera: ^0.10.0
  ```

- Request camera permissions in `AndroidManifest.xml`:

  ```xml
  <uses-permission android:name="android.permission.CAMERA"/>
  ```

- Initialize the camera in your Dart code:

  ```dart
  import 'package:camera/camera.dart';

  List<CameraDescription> cameras;

  Future<void> initCamera() async {
    cameras = await availableCameras();
    CameraController controller = CameraController(cameras[0], ResolutionPreset.high);
    await controller.initialize();
  }
  ```

### 2. GPS Initialization (Using OpenStreetMap)

- Add the `location` and `flutter_map` dependencies in `pubspec.yaml`:

  ```yaml
  dependencies:
    location: ^4.3.0
    flutter_map: ^0.14.0
  ```

- Request location permissions in `AndroidManifest.xml`:

  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  ```

- Initialize GPS in your Dart code:

  ```dart
  import 'package:location/location.dart';

  Location location = Location();

  Future<void> initGPS() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData locationData = await location.getLocation();
    // Use locationData.latitude and locationData.longitude
  }
  ```

### 3. Bluetooth Initialization

- Add the `flutter_blue` dependency in `pubspec.yaml`:

  ```yaml
  dependencies:
    flutter_blue: ^0.8.0
  ```

- Request Bluetooth permissions in `AndroidManifest.xml`:

  ```xml
  <uses-permission android:name="android.permission.BLUETOOTH"/>
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
  ```

- Initialize Bluetooth in your Dart code:

  ```dart
  import 'package:flutter_blue/flutter_blue.dart';

  FlutterBlue flutterBlue = FlutterBlue.instance;

  Future<void> initBluetooth() async {
    // Start scanning for Bluetooth devices
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    // Listen for scan results
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');
        // Pair with device if needed
      }
    });
  }
  ```

### 4. Microphone Initialization

- Add the `audio_recorder` dependency in `pubspec.yaml`:

  ```yaml
  dependencies:
    audio_recorder: ^1.0.0
  ```

- Request microphone permission in `AndroidManifest.xml`:

  ```xml
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  ```

- Initialize microphone in your Dart code:

  ```dart
  import 'package:audio_recorder/audio_recorder.dart';

  Future<void> initMicrophone() async {
    bool hasPermissions = await AudioRecorder.hasPermissions;
    if (hasPermissions) {
      await AudioRecorder.start();
      // Stop recording later using await AudioRecorder.stop();
    }
  }
  ```

### 5. Accelerometer Initialization

- Add the `sensors_plus` dependency in `pubspec.yaml`:

  ```yaml
  dependencies:
    sensors_plus: ^2.0.0
  ```

- Initialize accelerometer in your Dart code:

  ```dart
  import 'package:sensors_plus/sensors_plus.dart';

  void initAccelerometer() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      print('X: ${event.x}, Y: ${event.y}, Z: ${event.z}');
    });
  }
  ```

### 6. Firestore Database Initialization

- Add the `cloud_firestore` dependency in `pubspec.yaml`:

  ```yaml
  dependencies:
    cloud_firestore: ^3.1.0
  ```

- Initialize Firebase in your `main.dart`:

  ```dart
  import 'package:firebase_core/firebase_core.dart';

  Future<void> main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    runApp(MyApp());
  }
  ```

- Use Firestore in your Dart code:

  ```dart
  import 'package:cloud_firestore/cloud_firestore.dart';

  Future<void> addData() async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    await users.add({
      'name': 'John Doe',
      'age': 30,
    });
  }
  ```

### Running the Application

- Ensure to run the application on an Android Virtual Device (AVD) or a physical smartphone.

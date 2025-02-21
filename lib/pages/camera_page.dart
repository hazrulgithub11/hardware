import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  late CameraDescription _camera;
  bool _isCameraReady = false;
  bool _isRecording = false;
  // ignore: unused_field
  String? _mediaPath;
  String _selectedMode = 'Photo'; // Modes: Photo, Video, QR Scanner
  String? _scannedQRCode; // Holds the scanned QR code

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    var cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      print("Camera permission denied");
      return;
    }

    var storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      print("Storage permission denied");
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _camera = _cameras.first; // Default to rear camera
    _controller = CameraController(_camera, ResolutionPreset.high);
    await _controller.initialize();
    setState(() {
      _isCameraReady = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final directory =
          Directory('/storage/emulated/0/Download'); // Downloads directory
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final filePath =
          '${directory.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      XFile file = await _controller.takePicture();
      await file.saveTo(filePath); // Save the photo to Downloads directory

      setState(() {
        _mediaPath = filePath;
      });
      _saveToFirestore(filePath, 'photo'); // Save photo metadata in Firestore
      _showSnackBar("Photo saved to Downloads: $filePath");
    } catch (e) {
      print("Error capturing photo: $e");
    }
  }

  Future<void> _recordVideo() async {
    final directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final filePath =
        '${directory.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    if (_isRecording) {
      XFile videoFile = await _controller.stopVideoRecording();
      File savedVideo = File(videoFile.path);
      savedVideo.copySync(filePath); // Save the video to Downloads directory

      setState(() {
        _isRecording = false;
      });
      _saveToFirestore(filePath, 'video'); // Save video metadata in Firestore
      _showSnackBar("Video saved to Downloads: $filePath");
    } else {
      await _controller.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _saveToFirestore(String filePath, String mediaType) async {
    try {
      FirebaseFirestore.instance.collection('media').add({
        'filePath': filePath,
        'timestamp': FieldValue.serverTimestamp(),
        'mediaType': mediaType,
      });
    } catch (e) {
      print("Error saving to Firestore: $e");
    }
  }

  Future<void> _saveQRCodeToFirestore(String code) async {
    try {
      FirebaseFirestore.instance.collection('qr_codes').add({
        'code': code,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showSnackBar("QR Code saved to Firestore: $code");
    } catch (e) {
      print("Error saving QR code to Firestore: $e");
    }
  }

  Future<void> _redirectToURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _showSnackBar("Could not launch $url");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Camera App')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                CameraPreview(_controller),
                if (_selectedMode == 'QR Scanner')
                  MobileScanner(
                    onDetect: (BarcodeCapture barcodeCapture) {
                      if (barcodeCapture.barcodes.isNotEmpty) {
                        final String code =
                            barcodeCapture.barcodes.first.displayValue ??
                                'Unknown';
                        setState(() {
                          _scannedQRCode = code;
                        });
                        _saveQRCodeToFirestore(code);
                        _redirectToURL(code); // Redirect to URL
                      }
                    },
                  ),
                if (_selectedMode == 'QR Scanner' && _scannedQRCode != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      color: Colors.black.withOpacity(0.6),
                      child: Text(
                        'Scanned: $_scannedQRCode',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeButton('Photo', Icons.camera_alt),
            _buildModeButton('Video', Icons.videocam),
            _buildModeButton('QR Scanner', Icons.qr_code_scanner),
          ],
        ),
        if (_selectedMode == 'Video')
          IconButton(
            onPressed: _recordVideo,
            icon: Icon(
              _isRecording ? Icons.stop : Icons.fiber_manual_record,
              color: _isRecording ? Colors.red : Colors.blue,
              size: 40,
            ),
          ),
        if (_selectedMode == 'Photo')
          IconButton(
            onPressed: _capturePhoto,
            icon: Icon(Icons.camera, size: 40),
          ),
      ],
    );
  }

  Widget _buildModeButton(String mode, IconData icon) {
    return IconButton(
      onPressed: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      icon: Icon(
        icon,
        color: _selectedMode == mode ? Colors.blue : Colors.grey,
      ),
    );
  }
}

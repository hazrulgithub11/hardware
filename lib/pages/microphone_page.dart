import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class MicrophonePage extends StatefulWidget {
  const MicrophonePage({Key? key}) : super(key: key);

  @override
  _MicrophonePageState createState() => _MicrophonePageState();
}

class _MicrophonePageState extends State<MicrophonePage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  String? _currentFilePath;
  bool _hasPermission = false;

  List<DocumentSnapshot> _recordedAudios =
      []; // List of recordings from Firestore

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _requestPermissions();
    _fetchRecordedAudios();
  }

  Future<void> _initializeRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      setState(() {
        _hasPermission = false;
      });
      print('Microphone permission denied');
    }
  }

  Future<String> _getFilePath() async {
    final directory = await getExternalStorageDirectory();
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    return '${directory!.path}/$fileName';
  }

  void _startRecording() async {
    if (_hasPermission) {
      try {
        _currentFilePath = await _getFilePath();
        await _recorder.startRecorder(toFile: _currentFilePath);
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        print("Error starting recording: $e");
      }
    } else {
      print('Microphone permission not granted');
    }
  }

  void _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      if (_currentFilePath != null) {
        await _storeAudioMetadata(_currentFilePath!);
        _fetchRecordedAudios();
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> _storeAudioMetadata(String filePath) async {
    final fileName = filePath.split('/').last;
    final fileSize = await File(filePath).length();

    try {
      await FirebaseFirestore.instance.collection('audio').add({
        'path': filePath,
        'name': fileName,
        'size': fileSize,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error storing metadata: $e");
    }
  }

  Future<void> _fetchRecordedAudios() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('audio')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _recordedAudios = querySnapshot.docs;
      });
    } catch (e) {
      print("Error fetching audio list: $e");
    }
  }

  void _deleteRecording(DocumentSnapshot audio) async {
    try {
      final String filePath = audio['path'];
      await File(filePath).delete(); // Delete file locally
      await FirebaseFirestore.instance
          .collection('audio')
          .doc(audio.id)
          .delete(); // Delete metadata from Firestore
      _fetchRecordedAudios(); // Refresh the list
    } catch (e) {
      print("Error deleting audio: $e");
    }
  }

  void _playAudio(String filePath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print("Error pausing audio: $e");
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Microphone Recorder')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label:
                      Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _recordedAudios.isEmpty
                  ? const Center(child: Text('No recordings available.'))
                  : ListView.builder(
                      itemCount: _recordedAudios.length,
                      itemBuilder: (context, index) {
                        var audio = _recordedAudios[index];
                        final String filePath = audio['path'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(audio['name'] ?? 'Unknown'),
                            subtitle: Text(
                                'Size: ${(audio['size'] / 1024).toStringAsFixed(2)} KB'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () => _playAudio(filePath),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.pause),
                                  onPressed: _pauseAudio,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteRecording(audio),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

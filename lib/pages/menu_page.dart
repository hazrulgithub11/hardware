import 'package:flutter/material.dart';
import 'accelerometer_page.dart';
import 'bluetooth_page.dart';
import 'camera_page.dart';
import 'gps_page.dart';
import 'microphone_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Menu'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Camera'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => CameraPage()));
            },
          ),
          ListTile(
            title: const Text('GPS'),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => GPSPage()));
            },
          ),
          ListTile(
            title: const Text('Bluetooth'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BluetoothPage(title: 'Bluetooth Control'),
                ),
              );
            },
          ),
          // ListTile(
          //   title: const Text('Bluetooth'),
          //   onTap: () {
          //     Navigator.push(context,
          //         MaterialPageRoute(builder: (context) => BluetoothPage()));
          //   },
          // ),
          ListTile(
            title: const Text('Microphone'),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MicrophonePage()));
            },
          ),
          ListTile(
            title: const Text('Accelerometer'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AccelerometerPage()));
            },
          ),
        ],
      ),
    );
  }
}

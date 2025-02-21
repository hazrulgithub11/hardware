import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hardwarelab/firebase_options.dart';
import 'pages/menu_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is ready
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Print Firebase initialization error for better debugging
    print("Firebase Initialization Error: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hardware Access App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:
          MenuPage(), // Show the menu page directly once Firebase is initialized
    );
  }
}

import 'package:appshine/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase engine import
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/firebase_options.dart'; // Firebase keys import

// Async main for waiting flutter widgets and Firebase initialize
void main() async {
  // Flutter init ensure
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase using the options of the Firebase generated file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

 @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Delete debug banner
      home: AuthGate(), // AuthGate choose the home depending on user login status
    );
  }
}
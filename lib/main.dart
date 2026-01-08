import 'package:appshine/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase engine import
import 'data/firebase_options.dart'; // Firebase keys import
import 'presentation/screens/login_screen.dart';

// Async main for waiting flutter widgets and Firebase initialize
void main() async {
  // Flutter init ensure
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase using the options of the Firebase generated file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

 @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Quita la etiqueta "Debug" de la esquina
      home: LoginScreen(), // Llamamos a la pantalla que queramos de inicio
    );
  }
}
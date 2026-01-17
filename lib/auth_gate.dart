import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Escuchamos si hay usuario o no de Firebase Auth
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si hay datos es que hay usuario logueado y vamos a HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Si no hay datos de login, vamos al Login.
        return const LoginScreen();
      },
    );
  }
}
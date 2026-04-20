import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// Authentication gate widget that manages navigation based on user login state.
///
/// Listens to Firebase authentication state changes and displays [HomeScreen] for
/// authenticated users or [LoginScreen] for unauthenticated users.
class AuthGate extends StatelessWidget {
  /// Creates an [AuthGate] widget.
  const AuthGate({super.key});

  /// Builds the authentication gate using a StreamBuilder listening to Firebase auth state.
  ///
  /// Returns:
  /// * [HomeScreen] if user is authenticated
  /// * [LoginScreen] if user is not authenticated
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
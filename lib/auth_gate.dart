import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

/// Authentication gate widget that manages navigation based on user login state.
///
///
/// **How it works:**
/// - Listens to Firebase authentication state changes via [FirebaseAuth.instance.authStateChanges()]
/// - Uses a [StreamBuilder] to reactively rebuild when auth state changes
/// - If user is authenticated: displays [HomeScreen] (main app content)
/// - If user is not authenticated: displays [LoginScreen] (login/signup)
///
/// **Firebase Integration:**
/// This widget relies on Firebase Authentication being properly configured
/// in the app. When the user logs in/out, Firebase automatically notifies
/// all listeners, causing this widget to rebuild and navigate accordingly.
class AuthGate extends StatelessWidget {
  /// Creates an [AuthGate] widget.
  const AuthGate({super.key});

  /// Builds the authentication gate using a StreamBuilder.
  ///
  /// **Implementation Details:**
  /// Uses [StreamBuilder<User?>] to listen to Firebase authentication state changes.
  /// This approach is chosen for:
  /// - Automatic reactivity: rebuilds UI whenever auth state changes (login, logout, etc.)
  /// - Memory efficiency
  /// - Native Firebase integration: direct support for auth state streams
  /// - Clean architecture: UI responds to state without manual listeners or callbacks
  ///
  /// **How it works:**
  /// The stream emits the current User state immediately and continuously monitors
  /// Firebase Authentication for any changes. When state changes, the builder
  /// function is called to rebuild with the new snapshot data.
  ///
  /// Parameters:
  /// * [context]: The build context for building the widget tree
  /// 
  /// Returns:
  /// A [StreamBuilder<User?>] that displays:
  /// - [HomeScreen] if user is authenticated
  /// - [LoginScreen] if user is not authenticated
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to Firebase authentication state changes.
      // This stream emits immediately with the current state and continuously
      // monitors for any changes (login, logout, session expiry, etc.)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If snapshot has data, a user is authenticated. Navigate to main app.
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // If snapshot is null/empty, user is not authenticated. Show login form.
        return const LoginScreen();
      },
    );
  }
}
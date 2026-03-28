import 'package:flutter/material.dart';
import '../data/auth_repository.dart'; // Importamos la lógica de autenticación
import '../l10n/app_localizations.dart'; // Importamos las traducciones

/// Login and registration screen for user authentication.
///
/// This screen provides a unified interface for both login and registration modes,
/// allowing users to authenticate via email/password or Google Sign-In.
/// Contains error handling with SnackBar notifications
///
/// **Dependencies:**
///   * AuthRepository: Handles Firebase authentication logic
///   * AppLocalizations: Provides multi-language support
class LoginScreen extends StatefulWidget {
  /// Creates a LoginScreen widget.
  ///
  /// The [key] parameter is optional and used to identify this widget in the widget tree.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// State manager for LoginScreen.
///
/// Manages user input, authentication state, and mode transitions between
/// login and registration.
class _LoginScreenState extends State<LoginScreen> {
  /// Controller for the email input field.
  final emailController = TextEditingController();

  /// Controller for the password input field.
  final passwordController = TextEditingController();

  /// Instance of the authentication repository.
  ///
  /// Provides Firebase authentication methods (signIn, signUp, signInWithGoogle).
  final authRepository = AuthRepository();

  /// Tracks whether user is in login mode (true) or registration mode (false).
  bool isLogin = true;

  /// Initiates Google Sign-In authentication flow.
  ///
  /// Attempts to sign in using Google credentials. If authentication succeeds,
  /// the user is redirected by Firebase (via AuthGate). If it fails, displays
  /// an error message via SnackBar.
  ///
  /// This method is async and safe to call multiple times - Firebase handles
  /// the OAuth flow and state management.
  void signInWithGoogle() async {
    try {
      await authRepository.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // Show error message of Firebase authentication failure
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red), 
        );
      }
    }
  }

  /// Submits authentication form for login or registration.
  ///
  /// Attempts to sign in or register using [AuthRepository]. Shows error messages
  /// only if the screen is still visible (safe navigation when user leaves).
  ///
  /// Behavior: If [isLogin] is true, attempts sign-in; otherwise, attempts registration.
  void submit() async {
    try {
      if (isLogin) {
        // Use repository to sign in
        await authRepository.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        // Use repository to sign up
        await authRepository.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Builds the authentication UI.
  ///
  /// Constructs a full-screen authentication interface with all necessary controls
  /// for login and registration.
  ///
  /// Returns:
  ///   A [Scaffold] that builds the login/registration form with AppBar and body SingleChildScrollView.
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      // AppBar with dynamic title based on current authentication mode
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Appshine', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(
              isLogin ? loc.translate('login') : loc.translate('registerMode'),
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 200,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(55.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email input field
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: loc.translate('email')),
              keyboardType: TextInputType.emailAddress,
            ),
            // Password input field with obscured text
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: loc.translate('password')),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Primary action button - text changes based on authentication mode
            // Shows "Login" or "Register" with full width
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                child: Text(isLogin ? loc.translate('enterButton') : loc.translate('registerButton')),
              ),
            ),

            const SizedBox(height: 10),

            // Google authentication button for OAuth sign-in/sign-up
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: signInWithGoogle,
                icon: const Icon(Icons.login),
                label: Text(loc.translate('continueWithGoogle')),
              ),
            ),

            const SizedBox(height: 10),

            // Mode toggle button to switch between login and registration
            // Toggles [isLogin] state and rebuilds UI with corresponding labels
            TextButton(
              onPressed: () {
                setState(() {
                  isLogin = !isLogin;
                });
              },
              child: Text(
                isLogin
                    ? loc.translate('noAccount')
                    : loc.translate('hasAccount'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

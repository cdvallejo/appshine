import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Repository for handling user authentication and related Firestore operations.
/// 
/// Provides a clean interface for the rest of the app to use for
/// signing up, signing in, signing out, and Google Sign-In functionality.
/// 
class AuthRepository {
  /// Firebase Authentication instance for handling user authentication
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  /// Firestore instance for managing user data persistence
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Google Sign-In instance for OAuth authentication
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Gets the currently authenticated user.
  ///
  /// Returns:
  /// * The authenticated [User] if logged in, or null if no user is authenticated.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Creates a new user account with email and password.
  ///
  /// Creates a Firebase Authentication user and a corresponding document in Firestore
  /// with the user's basic information. All new users are set as non-admin by default.
  ///
  /// Parameters:
  /// * [email]: The email address for the new account.
  /// * [password]: The password for the new account.
  ///
  /// Returns:
  /// * Completes when the account is created successfully.
  ///
  /// Throws [Exception] if account creation fails (e.g., invalid email, weak password, email already in use).
  Future<void> signUp({required String email, required String password}) async {
    try {
      // User creation with Firebase Auth
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After successful sign up, create a user document in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'createdAt': Timestamp.now(),
          'isAdmin': false, // Por seguridad
          // TODO: allow users to set displayName
        });
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Authenticates a user with email and password.
  ///
  /// Validates user credentials against Firebase Authentication and logs in the user
  /// if the credentials are correct. Persists the session on the device.
  ///
  /// Parameters:
  /// * [email]: The user's email address.
  /// * [password]: The user's password.
  ///
  /// Returns:
  /// * Completes when authentication is successful.
  ///
  /// Throws [Exception] if authentication fails (e.g., incorrect credentials, user not found).
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Signs out the currently authenticated user.
  ///
  /// Clears the authentication session from Firebase and revokes access tokens
  /// from Google Sign-In if the user was logged in via Google OAuth.
  ///
  /// Returns:
  /// * Completes when the sign-out process is finished.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  /// Authenticates a user using Google Sign-In (OAuth).
  ///
  /// Initiates Google OAuth flow, obtains authentication tokens, and logs in the user
  /// through Firebase. If the user is new, creates a Firestore document with their
  /// basic information (uid, email, authProvider).
  /// Reuses existing Firebase account if already connected to the same Google account.
  ///
  /// Returns:
  /// * Completes when authentication succeeds. Returns without error if user cancels.
  ///
  /// Throws [Exception] if OAuth flow fails (network issues, OAuth configuration problems).
  Future<void> signInWithGoogle() async {
    try {
      // Initiate the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Cancelled by user, simply return without error
        return;
      }

      // Obtain the authentication tokens from the Google Sign-In account
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase Authentication using the Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Check if the user is new and create a Firestore document if necessary
      if (userCredential.user != null) {
        final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        if (!userDoc.exists) {
          // New user, create Firestore document with Google profile info
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'createdAt': Timestamp.now(),
            'isAdmin': false,
            'authProvider': 'google', // New field for tracking auth method
          });
        }
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión con Google: ${e.toString()}');
    }
  }
}
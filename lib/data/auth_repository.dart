import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Repository for Firebase Authentication and Firestore user management.
///
/// Provides methods for email/password authentication, Google Sign-In, and sign-out.
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
  /// Also creates a Firestore user document with basic information (all users start as non-admin).
  ///
  /// Parameters:
  /// * [email] - The email address for the new account
  /// * [password] - The password for the new account
  ///
  /// Throws [Exception] if account creation fails (invalid email, weak password, email already in use).
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
  /// Parameters:
  /// * [email] - The user's email address
  /// * [password] - The user's password
  ///
  /// Throws [Exception] if authentication fails (incorrect credentials or user not found).
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
  /// Clears the authentication session and revokes Google OAuth tokens if applicable.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
  }

  /// Authenticates a user using Google Sign-In (OAuth).
  ///
  /// Initiates Google OAuth flow and creates a Firestore user document if new.
  /// Reuses existing account if already connected to the same Google account.
  ///
  /// Throws [Exception] if OAuth fails (network issues or configuration problems).
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
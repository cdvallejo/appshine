import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  // Instancia de Firebase Auth (la herramienta oficial)
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para saber si hay alguien logueado ahora mismo
  User? get currentUser => _firebaseAuth.currentUser;

  // SignUp method
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
          // Aquí podríamos añadir 'userName' si lo pidiéramos en el formulario
        });
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

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

  // Método para cerrar sesión
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
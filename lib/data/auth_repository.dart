import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  // Instancia de Firebase Auth (la herramienta oficial)
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Método para saber si hay alguien logueado ahora mismo
  User? get currentUser => _firebaseAuth.currentUser;

  // Método para registrarse (Email y contraseña)
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      // Si falla (ej: correo ya existe), lanzamos el error para que la UI lo sepa
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
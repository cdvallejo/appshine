import 'package:flutter/material.dart';
import '../data/auth_repository.dart'; // Importamos la lógica de autenticación
import '../l10n/app_localizations.dart'; // Importamos las traducciones

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para leer lo que escribe el usuario
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Instancia de nuestro repositorio de autenticación (la lógica)
  final authRepository = AuthRepository();

  bool isLogin = true;

  // Función para registrarse/iniciar sesión con Google
  void signInWithGoogle() async {
    try {
      await authRepository.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Función para registrarse
  void submit() async {
    try {
      if (isLogin) {
        // Usamos el repositorio para iniciar sesión
        await authRepository.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        // Usamos el repositorio para registrarse
        await authRepository.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } catch (e) {
      // Si falla, mostramos un aviso abajo (SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      // El título cambia según el modo
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
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: loc.translate('email')),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: loc.translate('password')),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Botón principal (El texto cambia)
            SizedBox(
              width: double.infinity, // Para que ocupe todo el ancho
              child: ElevatedButton(
                onPressed: submit,
                child: Text(isLogin ? loc.translate('enterButton') : loc.translate('registerButton')),
              ),
            ),

            const SizedBox(height: 10),

            // Botón de Google Sign In
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: signInWithGoogle,
                icon: const Icon(Icons.login),
                label: Text(loc.translate('continueWithGoogle')),
              ),
            ),

            const SizedBox(height: 10),

            // Botón mágico para cambiar de modo
            TextButton(
              onPressed: () {
                // Al pulsar, invertimos el valor (true -> false, false -> true)
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

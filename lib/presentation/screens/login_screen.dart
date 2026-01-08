import 'package:flutter/material.dart';
import '../../data/auth_repository.dart'; // Importamos la lógica de autenticación

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
    return Scaffold(
      // El título cambia según el modo
      appBar: AppBar(
        title: Text(isLogin ? 'Iniciar Sesión' : 'Registro Appshine'),
        centerTitle: true,
        toolbarHeight: 200,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(45.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Botón principal (El texto cambia)
            SizedBox(
              width: double.infinity, // Para que ocupe todo el ancho
              child: ElevatedButton(
                onPressed: submit,
                child: Text(isLogin ? 'Entrar' : 'Registrarse'),
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
                    ? '¿No tienes cuenta? Regístrate aquí'
                    : '¿Ya tienes cuenta? Inicia sesión',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

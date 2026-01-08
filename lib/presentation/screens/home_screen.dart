import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appshine'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // No hace falta navegar a ningún sitio. 
              // ¡El AuthGate detectará que te has ido y te llevará al Login solo!
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.movie, size: 80, color: Colors.indigo),
            SizedBox(height: 20),
            Text(
              'Bienvenido a Appshine',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
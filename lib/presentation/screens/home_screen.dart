import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appshine'),
        backgroundColor: Colors.indigo, // Un color para que destaque
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
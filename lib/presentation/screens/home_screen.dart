import 'package:appshine/repositories/tmdb_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current authenticated user
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appshine'),
        backgroundColor: Colors.indigo,
        actions: [
          // FutureBuilder to check if the user has administrative privileges
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .get(),
            builder: (context, snapshot) {
              // 1. Connection check: While waiting for the "package", we return an empty space
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              // 2. Data check: Once the snapshot is "crushed" with real data, we check for isAdmin
              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;

                // If isAdmin is true, show the admin settings icon
                if (userData['isAdmin'] == true) {
                  return IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    tooltip: 'Admin Panel',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminScreen(),
                        ),
                      );
                    },
                  );
                }
              }
              // Return an empty widget if the user is not an admin
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // AuthGate will automatically handle the redirection to Login
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Fetch user data again to customize the welcome message
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get(),
        builder: (context, snapshot) {
          // 1. Connection check: Show a loading indicator while fetching data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          String welcomeMessage = 'Welcome to Appshine';

          // 2. Data check: The snapshot is updated with user info
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            // Customize message based on user role stored in Firestore
            if (userData['isAdmin'] == true) {
              welcomeMessage = 'Welcome, Admin!';
            } else {
              welcomeMessage = 'Hello, ${userData['email']}';
            }
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.movie, size: 80, color: Colors.indigo),
                const SizedBox(height: 20),
                Text(welcomeMessage, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // 1. Instanciamos el repositorio
                    final tmdb = TMDBRepository();

                    // 2. Llamamos a la búsqueda
                    print('Buscando en TMDB...');
                    final movies = await tmdb.searchMovies('eternal sunshine of the spotless mind');

                    // 3. Imprimimos los resultados en consola
                    if (movies.isNotEmpty) {
                      for (var movie in movies) {
                        print('Película: ${movie.title} - ID: ${movie.id}');
                      }
                    } else {
                      print('No se encontraron películas.');
                    }
                  },
                  child: const Text('Probar API TMDB'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

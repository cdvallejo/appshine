import 'package:appshine/models/movie_model.dart';
import 'package:appshine/screens/add_moment_screen.dart';
import 'package:appshine/widgets/movie_search_delegate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_screen.dart';
import 'package:appshine/data/database_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // --- MAIN STRUCTURE OF THE SCREEN ---
    return Scaffold(
      // --- APP BAR ---
      appBar: AppBar(
        title: const Text('Appshine'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.indigo,
        actions: [
          // AppBar admin button visibility based on user role
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasData && snapshot.data!.exists) {
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                if (userData['isAdmin'] == true) {
                  return IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminScreen(),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
        ],
      ),

      // --- BODY OF THE SCREEN ---
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          bool isAdmin = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            isAdmin = userData['isAdmin'] == true;
          }
          // If the user is an admin, show a special message
          if (isAdmin) {
            return const Center(
              child: Text('Welcome, Admin', style: TextStyle(fontSize: 24)),
            );
          }

          // If user is not admin, show their moments
          return StreamBuilder<QuerySnapshot>(
            stream: DatabaseService().getMomentsStream(),
            builder: (context, momentSnapshot) {
              if (momentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = momentSnapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Center(
                  child: Text('No moments added yet. Tap + to add one!'),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  // Card for each moment
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: data['posterUrl'] != null
                              ? Image.network(
                                  data['posterUrl'],
                                  width: 50,
                                  height: 75,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.movie, size: 50),
                                )
                              : const Icon(Icons.movie, size: 50),
                        ),
                        title: Text(
                          data['title'] ?? 'Untitled',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Dir: ${data['director'] ?? 'N/A'}'),
                            Text(
                              'Año: ${data['year'] ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.indigo,
                        ),
                        onTap: () {
                          // Future detail screen
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // --- FLOATING BUTTON TO ADD MOMENT ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final Movie? movieSelected = await showSearch<Movie?>(
            context: context,
            delegate: MovieSearchDelegate(),
          );

          if (movieSelected != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddMomentScreen(movie: movieSelected),
              ),
            );
          }
        },
      ),
    );
  }
}

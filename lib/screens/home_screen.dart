import 'package:appshine/models/movie_model.dart';
import 'package:appshine/screens/add_moment_screen.dart';
import 'package:appshine/screens/moment_detail_screen.dart';
import 'package:appshine/widgets/movie_search_delegate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
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

              // --- GROUPED LIST VIEW BY DATE ---
              return GroupedListView<dynamic, DateTime>(
                elements: docs,
                groupBy: (doc) {
                  // Extract date without time
                  DateTime date = (doc.data()['date'] as Timestamp).toDate();
                  return DateTime(date.year, date.month, date.day);
                },
                // --- GROUP HEADER DESIGN ---
                groupSeparatorBuilder: (DateTime date) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: weekday name
                      Text(
                        _getWeekdayName(date.weekday),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.indigo.withValues(alpha: 0.8),
                        ),
                      ),
                      // Right side: full date
                      Text(
                        "${date.day} de ${_getMonthName(date.month)} de ${date.year}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.1,
                          color: Colors.indigo.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  // --- ITEM DESIGN WITHIN GROUP --
                ),
                itemBuilder: (context, dynamic doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Moment card design
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
                        // Traiing with icon moment and onTap for future detail
                        trailing: Icon(
                          _getMomentIcon(data['type']),
                          size:
                              20, // Lo subo a 20 para que se vea bien como acción
                          color: Colors.indigo.withValues(alpha: 0.5),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MomentDetailScreen(
                                momentData: data,
                                momentId: doc
                                    .id, // <--- Usamos 'doc.id' en lugar de 'docs[index].id'
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                // Date comparator to order groups
                itemComparator: (item1, item2) =>
                    (item2.data()['date'] as Timestamp).compareTo(
                      item1.data()['date'] as Timestamp,
                    ),
                useStickyGroupSeparators:
                    true, // Enable sticky headers for group separators
                floatingHeader:
                    false, // No floating header for no transparency between DateTime
                order: GroupedListOrder.DESC,
              );
            },
          );
        },
      ),
      // --- FLOATING BUTTON TO ADD MOMENT ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () =>
            _showAddMomentMenu(context), // Call the Moment menu function
      ),
    );
  }

  // Function to show the bottom sheet menu for adding moments
  void _showAddMomentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content height
          children: [
            const Text(
              'ADD A NEW MOMENT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // MOVIE OPTION
            ListTile(
              leading: const Icon(Icons.movie, color: Colors.indigo),
              title: const Text('Movie'),
              onTap: () async {
                Navigator.pop(context); // Close the menu
                final Movie? movieSelected = await showSearch<Movie?>(
                  context: context,
                  delegate: MovieSearchDelegate(),
                );
                if (movieSelected != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddMomentScreen(movie: movieSelected),
                    ),
                  );
                }
              },
            ),

            // BOOK OPTION
            ListTile(
              leading: const Icon(Icons.book, color: Colors.indigo),
              title: const Text('Book'),
              onTap: () {
                Navigator.pop(context);
                // SOON..
              },
            ),

            // EVENT OPTION
            ListTile(
              leading: const Icon(Icons.people, color: Colors.indigo),
              title: const Text('Event'),
              onTap: () {
                Navigator.pop(context);
                // SOON..
              },
            ),
          ],
        ),
      ),
    );
  }

  // Functions to get month and weekday names in English
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  IconData _getMomentIcon(String? type) {
    switch (type) {
      case 'movie':
        return Icons.movie_outlined;
      case 'book':
        return Icons.book_outlined;
      case 'place':
        return Icons.place_outlined;
      default:
        return Icons.question_mark_outlined; // Just in case
    }
  }
}

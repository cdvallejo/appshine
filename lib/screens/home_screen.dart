import 'package:appshine/models/book_model.dart';
import 'package:appshine/models/media_model.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:appshine/screens/add_moment_screen_media.dart';
import 'package:appshine/screens/add_moment_screen_book.dart';
import 'package:appshine/screens/add_moment_screen_social_event.dart';
import 'package:appshine/screens/moment_detail_screen.dart';
import 'package:appshine/screens/settings_screen.dart';
import 'package:appshine/widgets_extra/book_search_delegate.dart';
import 'package:appshine/widgets_extra/media_search_delegate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
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

          /* If USER is NOT ADMIN, show their moments
            StreamBuilder watches Firestore and auto-rebuilds.
            But when EDITING a moment in moment_detail_screen, to see changes immediately (without leaving the screen),
            we use setState() to update widget.momentData after saving to Firestore. */
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
                groupSeparatorBuilder: (DateTime date) => Container(
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.05),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
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
                  ),
                ),
                itemBuilder: (context, dynamic doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  // Moment item design
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: _buildMomentImage(
                          data['type'],
                          data['imageNames'],
                          data['imageUrl'],
                          data['subtype'],
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
                            Text(
                              _capitalize(data['subtype']),
                              style: const TextStyle(color: Colors.indigo),
                            ),

                            /*Text(
                              'Año: ${data['year'] ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),*/
                          ],
                        ),
                        // Traiing with icon moment and onTap for future detail
                        trailing: Icon(
                          _getMomentIcon(data['type'], data['subtype']),
                          size: 20,
                          color: Colors.indigo.withValues(alpha: 0.5),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MomentDetailScreen(
                                momentData: data,
                                momentId: doc
                                    .id, // Pass the document ID for future reference (e.g., deletion)
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

            // MEDIA OPTION
            ListTile(
              leading: const Icon(Icons.movie, color: Colors.indigo),
              title: const Text('Movie | TV Series'),
              onTap: () async {
                // 1. Launch the search FIRST (using the current context)
                final result = await showSearch<Media?>(
                  context: context,
                  delegate: MediaSearchDelegate(),
                );

                // 2. If the user pressed back (result is null), also close the menu
                if (result == null) {
                  if (context.mounted) {
                    Navigator.pop(context); // Close the choice menu
                  }
                  return;
                }

                // 3. If the user DID choose a movie...
                if (context.mounted) {
                  Navigator.pop(context);

                  // And navigate to the add screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMomentScreen(media: result),
                    ),
                  );
                }
              },
            ),

            // BOOK OPTION
            ListTile(
              leading: const Icon(Icons.book, color: Colors.indigo),
              title: const Text('Book'),
              onTap: () async {
                final result = await showSearch<Book?>(
                  context: context,
                  delegate: BookSearchDelegate(),
                );

                if (result == null) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  return;
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddMomentScreenBook(book: result),
                    ),
                  );
                }
              },
            ),

            // SOCIAL EVENT OPTION
            ListTile(
              leading: const Icon(Icons.people, color: Colors.indigo),
              title: const Text('Event'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMomentScreenSocialEvent(
                      socialEvent: SocialEvent(
                        title: 'New Event',
                        subtype: 'Dinner',
                      ),
                    ),
                  ),
                );
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

  IconData _getMomentIconBig(String type, String subtype) {
    switch (type) {
      case 'media':
        // For media, check subtype to differentiate between TV and Movies
        if (subtype.toLowerCase().contains('tv')) {
          return Icons.tv;
        }
        return Icons.movie; // Default to movie for other subtypes
      case 'book':
        return Icons.book;
      case 'socialEvent':
        return Icons.people;
      default:
        return Icons.question_mark_outlined; // Just in case
    }
  }

  IconData _getMomentIcon(String type, String subtype) {
    switch (type) {
      case 'media':
        // For media, check subtype to differentiate between TV and Movies
        if (subtype.toLowerCase().contains('tv')) {
          return Icons.tv_outlined;
        }
        return Icons.movie_outlined; // Default to movie for other subtypes
      case 'book':
        return Icons.book_outlined;
      case 'socialEvent':
        return Icons.people_outlined;
      default:
        return Icons.question_mark_outlined; // Just in case
    }
  }

  String _capitalize(String text) {
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  /// Build the moment image widget based on type
  /// For social events: shows image from local storage using filename
  /// For media/books: shows network image from imageUrl
  Widget _buildMomentImage(
    String type,
    dynamic imageNames,
    String? imageUrl,
    String subtype,
  ) {
    /* For social events, reconstruct path from filename and show local image.
    Not null and empty list check */
    if (type == 'socialEvent' &&
        imageNames != null &&
        (imageNames as List).isNotEmpty) {
      return FutureBuilder<String>(
        future: _getImagePath(imageNames[0]),
        builder: (context, snapshot) {
          if (snapshot.hasData && File(snapshot.data!).existsSync()) {
            return Image.file(
              File(snapshot.data!),
              width: 50,
              height: 75,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(_getMomentIconBig(type, subtype), size: 50),
            );
          }
          return Icon(_getMomentIconBig(type, subtype), size: 50);
        },
      );
    }

    // For media and books, show network image from imageUrl
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        width: 50,
        height: 75,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(_getMomentIconBig(type, subtype), size: 50),
      );
    }

    // Fallback: show icon
    return Icon(_getMomentIconBig(type, subtype), size: 50);
  }

  /// Reconstruct the full path to a social event image from its filename
  Future<String> _getImagePath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/social_events/$fileName';
  }
}

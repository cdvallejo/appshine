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
import 'package:appshine/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'admin_screen.dart';
import 'package:appshine/data/database_service.dart';

/// Home screen implementation for displaying user moments.
///
/// This screen serves as the main hub for viewing and managing moments
/// (movies, TV shows, books, and social events). It provides role-based
/// content: admins see a welcome message, while regular users see their
/// moments organized by date in descending order.
///
/// **Features:**
///   * Real-time moment list synchronized with Firestore
///   * Moments grouped and sorted by date (newest first)
///   * Locale-aware date formatting (Spanish and English)
///   * Image handling for local (social events) and network sources
///   * Floating action button to quickly add new moments
///   * Admin panel access for administrators
///
/// **Dependencies:**
///   * FirebaseAuth: User authentication and role checking
///   * Firestore: User and moment data storage
///   * AppLocalizations: Multi-language support
///
/// ## Main screen of the app displaying user's moments or admin welcome screen.
///
/// Shows different content based on user roles:
///   * Admins: See a welcome message
///   * Regular users: See a grouped list of their moments organized by date
///
/// The screen includes:
///   * App bar with admin button (if user is admin) and settings menu
///   * Body with moments list or admin message
///   * Floating action button to add new moments (media, books, or events)
class HomeScreen extends StatelessWidget {
  /// Creates a HomeScreen widget.
  ///
  /// The [key] parameter is optional and used to identify this widget in the widget tree.
  const HomeScreen({super.key});

  /// Builds the home screen widget.
  ///
  /// Constructs a Scaffold with:
  ///   * An app bar with navigation and admin controls
  ///   * A body that shows admin message or moments list
  ///   * A floating action button to add moments
  ///
  /// The screen fetches user role from Firestore and displays
  /// appropriate content. Non-admin users see a grouped list of moments
  /// organized by date with newest first.
  ///
  /// Parameters:
  ///   * [context] - The build context
  ///
  /// Returns:
  ///   A Scaffold widget containing the home screen layout
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);

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
            return Center(
              child: Text(loc.translate('welcome'), style: const TextStyle(fontSize: 24)),
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
                          _getWeekdayName(context, date.weekday),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.indigo.withValues(alpha: 0.8),
                          ),
                        ),
                        // Right side: full date
                        Text(
                          _formatDate(context, date),
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
                          data['title'] ?? loc.translate('untitled'),
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

  /// Shows a modal bottom sheet menu for adding different types of moments.
  ///
  /// Displays three options: Movies/TV shows, books, and social events.
  /// Once the user selects an option, navigates to the corresponding
  /// input screen or closes the menu if tap outside.
  ///
  /// Note: The menu handles context.mounted checks to prevent navigation
  /// errors if the widget is disposed while async operations are in progress.
  /// Each option (media/book) opens a search delegate before navigating
  /// to the add moment screen.
  ///
  /// Parameters:
  ///   * [context] - The build context used to show the modal sheet
  void _showAddMomentMenu(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
            Text(
              loc.translate('addNewMoment').toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 20),

            // MEDIA OPTION
            ListTile(
              leading: const Icon(Icons.movie, color: Colors.indigo),
              title: Text(loc.translate('movieOrTv')),
              onTap: () async {
                // 1. Launch the search FIRST (using the current context)
                final result = await showSearch<Media?>(
                  context: context,
                  delegate: MediaSearchDelegate(searchLabel: loc.translate('searchByTitle')),
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
              title: Text(loc.translate('bookOrComic')),
              onTap: () async {
                final result = await showSearch<Book?>(
                  context: context,
                  delegate: BookSearchDelegate(searchLabel: loc.translate('searchByTitle')),
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
              title: Text(loc.translate('socialEvent')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMomentScreenSocialEvent(
                      socialEvent: SocialEvent(
                        title: loc.translate('newEvent'),
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

  /// Gets the localized month name for the given month number.
  ///
  /// Parameters:
  ///   * [context] - The build context to access localization
  ///   * [month] - The month number (1-12)
  ///
  /// Returns:
  ///   The localized month name
  String _getMonthName(BuildContext context, int month) {
    return AppLocalizations.of(context).getMonthName(month);
  }

  /// Gets the localized weekday name for the given weekday number.
  ///
  /// Parameters:
  ///   * [context] - The build context to access localization
  ///   * [weekday] - The weekday number (1=Monday through 7=Sunday)
  ///
  /// Returns:
  ///   The localized weekday name
  String _getWeekdayName(BuildContext context, int weekday) {
    return AppLocalizations.of(context).getWeekdayName(weekday);
  }

  /// Returns the icon for a moment type (filled version).
  ///
  /// Parameters:
  ///   * [type] - The moment type ('media', 'book', 'socialEvent')
  ///   * [subtype] - The moment subtype (used for media to differentiate TV vs Movies)
  ///
  /// Returns:
  ///   The appropriate MaterialIcon for the moment type
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
        return Icons.question_mark_outlined; // Just in case there is an error with the type / subtype
    }
  }

  /// Returns the icon for a moment type (outlined version).
  ///
  /// Parameters:
  ///   * [type] - The moment type ('media', 'book', 'socialEvent')
  ///   * [subtype] - The moment subtype (used for media to differentiate TV vs Movies)
  ///
  /// Returns:
  ///   The appropriate outlined MaterialIcon for the moment type
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

  /// Capitalizes the first character of a string.
  ///
  /// Parameters:
  ///   * [text] - The string to capitalize
  ///
  /// Returns:
  ///   The capitalized string, or the original if empty
  String _capitalize(String text) {
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  /// Formats a date according to the current locale.
  ///
  /// Shows Spanish format "26 de febrero de 2026" or English format
  /// "February 26, 2026" depending on device language settings.
  ///
  /// Parameters:
  ///   * [context] - The build context to access locale information
  ///   * [date] - The DateTime object to format
  ///
  /// Returns:
  ///   A formatted date string appropriate for the current locale
  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    
    if (locale.languageCode == 'en') {
      // English format: "February 26, 2026"
      return "${_getMonthName(context, date.month)} ${date.day}, ${date.year}";
    } else {
      // Spanish format: "26 de febrero de 2026"
      return "${date.day} de ${_getMonthName(context, date.month)} de ${date.year}";
    }
  }

  /// Builds the image widget for a moment display.
  ///
  /// Handles different image sources based on moment type:
  ///   * Social events: Loads image from local storage using filename
  ///   * Media/books: Loads network image from Firebase Storage URL
  ///   * Fallback: Shows icon if image is unavailable
  ///
  /// Note: Images are cached by Flutter's Image caching strategy.
  /// Network images use errorBuilder to show icons when loading fails.
  /// Local image files are checked for existence with [File.existsSync].
  ///
  /// Parameters:
  ///   * [type] - The moment type ('media', 'book', 'socialEvent')
  ///   * [imageNames] - List of filenames for social event images
  ///   * [imageUrl] - Network URL for media/book images
  ///   * [subtype] - The moment subtype (used for fallback icon)
  ///
  /// Returns:
  ///   A widget displaying the moment image or an icon placeholder
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
        future: _getImagePath(imageNames[0]), // Get the full path of the first image
        builder: (context, snapshot) { // Check if the file exists at the path, the result of the future is in snapshot.data
          if (snapshot.hasData && File(snapshot.data!).existsSync()) {
            return Image.file(
              File(snapshot.data!),
              width: 50,
              height: 75,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(_getMomentIconBig(type, subtype), size: 50), // Fallback to icon if file can't be loaded
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

  /// Reconstructs the full file path for a social event image.
  ///
  /// Completes the path by combining the application documents directory
  /// with the 'social_events' subdirectory and the provided filename.
  ///
  /// Note: This method assumes the file exists at the constructed path.
  /// Always check file existence before using the returned path.
  ///
  /// Parameters:
  ///   * [fileName] - The image filename (without directory path)
  ///
  /// Returns:
  ///   A Future that resolves to the complete file path string
  ///
  /// Example:
  ///   ```dart
  ///   final path = await _getImagePath('event_photo.jpg');
  ///   if (File(path).existsSync()) {
  ///     // Use the file
  ///   }
  ///   ```
  Future<String> _getImagePath(String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/social_events/$fileName';
  }
}

import 'package:appshine/models/book_model.dart';
import 'package:appshine/models/media_model.dart';
import 'package:appshine/models/social_event_model.dart';
import 'package:appshine/screens/add_moment_screen_media.dart';
import 'package:appshine/screens/add_moment_screen_book.dart';
import 'package:appshine/screens/add_moment_screen_social_event.dart';
import 'package:appshine/screens/insights_screen.dart';
import 'package:appshine/screens/moment_detail_screen.dart';
import 'package:appshine/screens/settings_screen.dart';
import 'package:appshine/widgets_extra/book_search_delegate.dart';
import 'package:appshine/widgets_extra/media_search_delegate.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:appshine/utils/image_thumbnail_service.dart';
import 'package:appshine/utils/tutorial_manager.dart';
import 'admin_screen.dart';
import 'package:appshine/data/database_service.dart';

/// Home screen implementation for displaying user moments.
///
/// This screen serves as the main hub for viewing and managing moments
/// (movies, TV shows, books, and social events). It provides role-based
/// content: admins see quick access buttons, while regular users see their
/// moments organized by date in descending order.
///
/// **Features:**
///   * Real-time moment list synchronized with Firestore
///   * Moments grouped and sorted by date (newest first)
///   * Locale-aware date formatting (Spanish and English)
///   * Image handling for local (social events) and network sources
///   * Floating action button to quickly add new moments (non-admin users)
///   * Admin panel with user management capabilities
///   * No drawer for admin users, settings icon on AppBar
///   * Tutorial/onboarding flow for new non-admin users (managed by [TutorialManager])
///
/// **Dependencies:**
///   * FirebaseAuth: User authentication and role checking
///   * Firestore: User and moment data storage
///   * AppLocalizations: Multi-language support
///   * TutorialManager: Handles tutorial initialization and display
///
/// Shows different content based on user roles:
///   * Admins: Admin Dashboard and Create Admin User buttons, settings icon on AppBar
///   * Regular users: Grouped list of moments with drawer navigation
///
/// The screen includes:
///   * App bar with settings icon (for admins)
///   * Drawer navigation (for regular users only)
///   * Body with moments list or admin buttons
///   * Floating action button to add new moments (non-admin users only)
class HomeScreen extends StatefulWidget {
  /// Creates a HomeScreen widget.
  ///
  /// The [key] parameter is optional and used to identify this widget in the widget tree.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // GlobalKeys for tutorial targets - used by TutorialManager to highlight UI elements
  /// Key for accessing Scaffold state (used to open/close drawer during tutorial)
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// Key for the FAB widget in tutorial target
  final GlobalKey fabKey = GlobalKey();
  
  /// Key for the Insights button in tutorial target
  final GlobalKey insightsKey = GlobalKey();
  
  /// Key for the Settings button in tutorial target
  final GlobalKey settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeTutorial();
  }

  /// Initializes and displays the tutorial for new non-admin users.
  /// 
  /// Creates a [TutorialManager] instance and delegates all tutorial logic
  /// - The tutorial is only shown once per user (tracked via SharedPreferences)
  /// - Uses async initialization to ensure it runs after the first frame is rendered and context is available.
  Future<void> _initializeTutorial() async {
    final tutorialManager = TutorialManager(
      context: context,
      scaffoldKey: scaffoldKey,
      fabKey: fabKey,
      insightsKey: insightsKey,
      settingsKey: settingsKey,
    );
    await tutorialManager.checkAndShowTutorialIfFirstTime();
  }

  /// Builds the home screen widget.
  ///
  /// Constructs a Scaffold with:
  ///   * An app bar with settings icon (for admins)
  ///   * A drawer for navigation (non-admin users only)
  ///   * A body that shows admin buttons or a grouped list of moments
  ///   * A floating action button to add moments (non-admin users only)
  ///
  /// The screen fetches user role from Firestore and displays appropriate content:
  /// - Admins see quick-access buttons to the admin panel
  /// - Non-admin users see a grouped list of moments organized by date (newest first)
  ///
  /// Returns a [FutureBuilder] that displays a loading indicator while fetching the user's admin status.
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context);

    // --- MAIN STRUCTURE OF THE SCREEN ---
    return FutureBuilder<bool>(
      future: _getIsAdmin(user?.uid),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          key: scaffoldKey,
          // --- DRAWER ---
          drawer: !isAdmin ? _buildDrawer(context, isAdmin, loc) : null,
          // --- APP BAR ---
          appBar: AppBar(
            title: const Text('Appshine'),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.settings),
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
          body: isAdmin
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.translate('welcome'),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 250,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.supervised_user_circle),
                          label: const Text('Admin Dashboard'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: DatabaseService().getMomentsStream(),
                  builder: (context, momentSnapshot) {
                    if (momentSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var docs = (momentSnapshot.data?.docs ?? []).toList();

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No moments added yet. Tap + to add one!'),
                      );
                    }

                    // Sort docs by date (ascending)
                    docs.sort((a, b) {
                      final dateA = (a['date'] as Timestamp).toDate();
                      final dateB = (b['date'] as Timestamp).toDate();
                      return dateA.compareTo(dateB);
                    });

                    // --- GROUPED LIST VIEW BY DATE ---
                    return GroupedListView<dynamic, DateTime>(
                      elements: docs,
                      groupBy: (doc) {
                        // Extract date without time
                        DateTime date = (doc.data()['date'] as Timestamp)
                            .toDate();
                        return DateTime(date.year, date.month, date.day);
                      },
                      // --- GROUP HEADER DESIGN ---
                      groupSeparatorBuilder: (DateTime date) => Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.05),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 6,
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.8),
                                ),
                              ),
                              // Right side: full date
                              Text(
                                _formatDate(context, date),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.1,
                                  color: Theme.of(context).colorScheme.primary,
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
                            vertical: 0,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListTile(
                            visualDensity: VisualDensity.compact,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            leading: _buildMomentImage(
                              data['type'],
                              data['imageNames'],
                              data['imageUrl'],
                              data['subtype'],
                              data['imageFileName'],
                            ),
                            title: Text(
                              data['title'] ?? loc.translate('untitled'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 1),
                                Text(
                                  loc.translate(
                                    AppLocalizations.getSubtypeKey(
                                      data['type'],
                                      data['subtype'],
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            // Trailing with icon moment and onTap for future detail
                            trailing: Icon(
                              _getMomentIconSmall(
                                data['type'],
                                data['subtype'],
                              ),
                              size: 20,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MomentDetailScreen(
                                    momentData: data,
                                    momentId: doc.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      useStickyGroupSeparators: true,
                      stickyHeaderBackgroundColor:
                          AppTheme.getStickyHeaderColor(context),
                      floatingHeader: false,
                      order: GroupedListOrder.DESC,
                    );
                  },
                ),

          // --- FLOATING BUTTON TO ADD MOMENT ---
          floatingActionButton:
              !isAdmin // Only show floating button for non-admin users
              ? FloatingActionButton(
                  key: fabKey,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => _showAddMomentMenu(context),
                )
              : null,
        );
      },
    );
  }

  /// Builds the drawer widget with different content for admins and regular users.
  Widget _buildDrawer(
    BuildContext context,
    bool isAdmin,
    AppLocalizations loc,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primaryColor),
            child: const Text(
              'Appshine',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!isAdmin)
            ListTile(
              key: insightsKey,
              leading: const Icon(Icons.insights),
              title: Text(loc.translate('insights')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InsightsScreen(),
                  ),
                );
              },
            ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.supervised_user_circle),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminScreen()),
                );
              },
            ),

          ListTile(
            key: settingsKey,
            leading: const Icon(Icons.settings),
            title: Text(loc.translate('settings')),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),

        ],
      ),
    );
  }

  /// Shows a modal bottom sheet menu for adding different types of moments.
  ///
  /// Displays three options: Movies/TV shows, Books, and Social events.
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
              leading: Icon(
                Icons.movie,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(loc.translate('movieOrTv')),
              onTap: () async {
                // 1. Launch the search FIRST (using the current context)
                final result = await showSearch<Media?>(
                  context: context,
                  delegate: MediaSearchDelegate(
                    searchLabel: loc.translate('searchByTitle'),
                  ),
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
              leading: Icon(
                Icons.book,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(loc.translate('bookOrComic')),
              onTap: () async {
                final result = await showSearch<Book?>(
                  context: context,
                  delegate: BookSearchDelegate(
                    searchLabel: loc.translate('searchByTitle'),
                  ),
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
              leading: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(loc.translate('socialEvent')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddMomentScreenSocialEvent(
                      socialEvent: SocialEvent(
                        title: loc.translate('newEvent'),
                        subtype: loc.translate('cultural'),
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

  /// Gets whether the current user is an admin.
  /// Checks the 'isAdmin' field in the user's Firestore document.
  ///
  /// Parameters:
  ///  * [uid] - The user ID to check (can be null)
  /// Returns:
  /// * A Future that resolves to true if the user is an admin, false otherwise
  Future<bool> _getIsAdmin(String? uid) async {
    if (uid == null) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.data()?['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      // Error handling
      return false;
    }
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
        if (subtype.toLowerCase().contains('cultural')) {
          return Icons.music_note;
        }
        if (subtype.toLowerCase().contains('gaming')) {
          return Icons.diversity_1;
        }
        if (subtype.toLowerCase().contains('hangout')) {
          return Icons.people;
        }
        if (subtype.toLowerCase().contains('milestone')) {
          return Icons.cake;
        }
        if (subtype.toLowerCase().contains('sport')) {
          return Icons.sports;
        }
        return Icons.people;
      default:
        return Icons
            .question_mark_outlined; // Just in case there is an error with the type / subtype
    }
  }

  /// Returns the icon for a moment type (outlined version - small for list trailing).
  ///
  /// Parameters:
  ///   * [type] - The moment type ('media', 'book', 'socialEvent')
  ///   * [subtype] - The moment subtype (used for media to differentiate TV vs Movies)
  ///
  /// Returns:
  ///   The appropriate outlined MaterialIcon for the moment type
  IconData _getMomentIconSmall(String type, String subtype) {
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
        if (subtype.toLowerCase().contains('cultural')) {
          return Icons.music_note_outlined;
        }
        if (subtype.toLowerCase().contains('gaming')) {
          return Icons.diversity_1_outlined;
        }
        if (subtype.toLowerCase().contains('hangout')) {
          return Icons.people_outlined;
        }
        if (subtype.toLowerCase().contains('milestone')) {
          return Icons.cake_outlined;
        }
        if (subtype.toLowerCase().contains('sport')) {
          return Icons.sports_outlined;
        }
        return Icons.people_outlined;
      default:
        return Icons.question_mark_outlined; // Just in case
    }
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

  /// Builds the image widget for a moment display (50×75px).
  ///
  /// Intelligent loading strategy:
  /// 1. For social events: Try local thumbnail (generated at 150×150, displayed at 50×75)
  /// 2. For media/books: Try local thumbnail (generated at 100×150, displayed at 50×75)
  /// 3. Network URL fallback with CachedNetworkImage for disk caching
  /// 4. Icon placeholder as last resort
  ///
  /// Parameters:
  ///   * [type] - The moment type ('media', 'book', 'socialEvent')
  ///   * [imageNames] - List of local image file names (for social events)
  ///   * [imageUrl] - The network image URL (for media/books)
  ///   * [subtype] - The moment subtype (used for icon fallback)
  ///   * [imageFileName] - The local image file name for media/books (if available)
  /// Returns:
  ///  A widget displaying the moment image or the icon with intelligent loading and fallbacks
  ///
  /// Notes:
  /// - For social events, we expect `imageNames` to be a list of local file names. We use the first one for the thumbnail.

  Widget _buildMomentImage(
    String type,
    dynamic imageNames,
    String? imageUrl,
    String subtype,
    String? imageFileName,
  ) {
    // Determine if we have local content (display: 50×75)
    String? localFileName;

    if (type == 'socialEvent' &&
        imageNames != null &&
        (imageNames as List).isNotEmpty) {
      localFileName = imageNames[0];
    } else if ((type == 'media' || type == 'book') && imageFileName != null) {
      localFileName = imageFileName;
    }

    // Strategy: Try local thumbnail first, fallback to network URL, then icon
    if (localFileName != null) {
      return _buildLocalThumbnail(localFileName, imageUrl, type, subtype);
    }

    // No local file, try network URL
    if (imageUrl != null) {
      return _buildNetworkImage(imageUrl, type, subtype);
    }

    // Final fallback: show icon
    return Icon(_getMomentIconBig(type, subtype), size: 50);
  }

  /// Builds a local thumbnail (50×75).
  /// Attempts to load a local thumbnail image. If the file doesn't exist or fails to load, falls back to network image.
  ///
  /// Parameters:
  /// * [fileName] - The local file name of the thumbnail image
  /// * [imageUrl] - Optional network URL fallback
  /// * [type] - The moment type (used for icon fallback)
  /// * [subtype] - The moment subtype (used for icon fallback)
  ///
  /// Returns:
  ///  A widget that displays the local thumbnail if it exists, otherwise tries network URL, then icon.
  Widget _buildLocalThumbnail(String fileName, String? imageUrl, String type, String subtype) {
    return FutureBuilder<String>(
      future: ImageThumbnailService.getThumbnailPath(fileName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (snapshot.hasData) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: 50,
              height: 75,
              fit: BoxFit.scaleDown,
              // If local file fails to load: try network image
              errorBuilder: (context, error, stackTrace) {
                if (imageUrl != null) {
                  return _buildNetworkImage(imageUrl, type, subtype);
                }
                return Icon(_getMomentIconBig(type, subtype), size: 50);
              },
            );
          }
        }

        // Local thumbnail doesn't exist → fallback to network URL
        if (imageUrl != null) {
          return _buildNetworkImage(imageUrl, type, subtype);
        }

        // No local file and no network URL → show icon
        return Icon(_getMomentIconBig(type, subtype), size: 50);
      },
    );
  }

  /// Builds a network image with CachedNetworkImage (50×75).
  /// Includes placeholder while loading and error widget fallback to icon.
  ///
  /// Parameters:
  ///  * [imageUrl] - The URL of the image to load
  ///  * [type] - The moment type (used for icon fallback)
  ///  * [subtype] - The moment subtype (used for icon fallback)
  ///
  /// Returns:
  /// A widget that displays the network image with caching, placeholder, and error handling
  Widget _buildNetworkImage(String imageUrl, String type, String subtype) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: 50,
      height: 75,
      fit: BoxFit.scaleDown,
      // While loading: show spinner
      placeholder: (context, url) => _buildLoadingWidget(),
      // If error loading: show icon
      errorWidget: (context, url, error) =>
          Icon(_getMomentIconBig(type, subtype), size: 50),
    );
  }

  /// Builds a loading indicator (50×75).
  /// Used as a placeholder while loading local thumbnails or network images.
  ///
  /// Returns:
  /// A widget containing a centered CircularProgressIndicator with specified dimensions
  Widget _buildLoadingWidget() {
    return const SizedBox(
      width: 50,
      height: 75,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

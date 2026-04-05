import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the tutorial flow for new users.
///
/// This class handles:
/// - Checking if a tutorial should be shown (only for non-admin users on first visit)
/// - Persisting tutorial view state using SharedPreferences
/// - Creating tutorial targets for different UI elements (FAB, Insights, Settings)
/// - Managing the tutorial coach mark and UI interactions
class TutorialManager {
  final BuildContext context;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final GlobalKey fabKey;
  final GlobalKey insightsKey;
  final GlobalKey settingsKey;

  // We use late initialization for the tutorial coach mark since it depends on the targets being built first
  late TutorialCoachMark tutorialCoachMark;
  final List<TargetFocus> targets = [];

  TutorialManager({
    required this.context,
    required this.scaffoldKey,
    required this.fabKey,
    required this.insightsKey,
    required this.settingsKey,
  });

  /// Checks if the tutorial should be shown and displays it if needed.
  ///
  /// Only shows the tutorial for non-admin users on their first visit.
  /// Uses SharedPreferences to persist viewing state per user
  /// Skips silently if user is admin, already saw tutorial, or Firebase auth is unavailable.
  Future<void> checkAndShowTutorialIfFirstTime() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if user is admin
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final isAdmin = userDoc.data()?['isAdmin'] ?? false;

      // Only show tutorial for non-admin users
      if (isAdmin) return;

      // Check if user has already seen the tutorial
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTutorial = prefs.getBool('tutorial_seen_${user.uid}') ?? false;
      if (hasSeenTutorial) return;

      // Wait for the UI to fully render
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        _showWelcomeDialog(isAdmin);
      }
    } catch (e) {
      debugPrint('Error showing tutorial: $e');
    }
  }

  /// Persists the tutorial as seen for the current user in SharedPreferences.
  ///
  /// Used by skip, finish, and welcome dialog actions to prevent re-showing the tutorial.
  Future<void> _markTutorialAsSeen() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorial_seen_${user.uid}', true); // Persist tutorial view state per user
    } catch (e) {
      debugPrint('Error marking tutorial as seen: $e');
    }
  }

  /// Displays the welcome dialog before starting the tutorial.
  ///
  /// Offers the user two options:
  /// - Skip: Marks tutorial as seen and closes the dialog
  /// - Start: Proceeds to show the tutorial with all targets
  /// 
  /// Returns:
  ///   A dialog with the welcome message if the context is still mounted, otherwise does nothing
  void _showWelcomeDialog(bool isAdmin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final loc = AppLocalizations.of(dialogContext);
        return AlertDialog(
          backgroundColor: AppTheme.primaryColor,
          title: Text(
            loc.translate('tourWelcomeTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
            ),
          ),
          content: Text(
            loc.translate('tourWelcomeDesc'),
            textAlign: TextAlign.justify,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Close and don't show tour
                _markTutorialAsSeen(); // User tutorial as seen
              },
              child: Text(
                loc.translate('tourSkip'),
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _addTargets(loc);
                _showTutorial(loc);
              },
              child: Text(
                loc.translate('tourStart'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds the list of tutorial targets (FAB, Insights, Settings).
  ///
  /// Note: This is only called for non-admin users (verified in checkAndShowTutorialIfFirstTime).
  void _addTargets(AppLocalizations loc) {
    targets.clear();

    // Target 1: FAB
    targets.add(
      TargetFocus(
        identify: "fab",
        keyTarget: fabKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('tourAddNewMoments'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      loc.translate('tourAddNewMomentsDesc'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
    );

    // Target 2: Insights
    targets.add(
      TargetFocus(
        identify: "insights",
        keyTarget: insightsKey,
        paddingFocus: -8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Padding(
              padding: const EdgeInsets.only(top: 150.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('tourInsights'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      loc.translate('tourInsightsDesc'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );

    // Target 3: Settings
    targets.add(
      TargetFocus(
        identify: "settings",
        keyTarget: settingsKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Padding(
              padding: const EdgeInsets.only(top: 150.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.translate('tourSettings'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      loc.translate('tourSettingsDesc'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Displays the tutorial coach mark with all targets and event handlers.
  ///
  /// Configures callbacks for:
  /// - onFinish: Marks tutorial as seen when user completes all targets
  /// - onSkip: Marks tutorial as seen when user skips
  /// - onClickTarget: Auto-opens drawer at FAB step, closes at Settings step
  ///
  /// The tutorial is automatically marked as viewed via `_markTutorialAsSeen()`.
  void _showTutorial(AppLocalizations loc) {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: AppTheme.primaryColor,
      textSkip: loc.translate('tourSkip'),
      alignSkip: Alignment.bottomLeft,
      onFinish: () {
        debugPrint("Tour finished");
        _markTutorialAsSeen(); // User tutorial as seen
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        debugPrint("Target: ${target.identify}");
      },
      onClickTarget: (target) {
        debugPrint("Clicked: ${target.identify}");
        // Auto-open drawer when finishing FAB target to show next targets
        if (target.identify == "fab") {
          Future.delayed(const Duration(milliseconds: 300), () {
            scaffoldKey.currentState?.openDrawer();
          });
        }
        // Close drawer when finishing Settings target
        if (target.identify == "settings") {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              Navigator.pop(context);
            }
          });
        }
      },
      onSkip: () {
        debugPrint("Tour skipped");
        _markTutorialAsSeen(); // User tutorial as seen
        return false;
      },
    );
    tutorialCoachMark.show(context: context);
  }
}

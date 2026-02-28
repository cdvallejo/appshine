import 'package:flutter/material.dart';

/// Centralized theme configuration for the Appshine application.
///
/// Provides light and dark theme data with consistent colors, typography,
/// and component styles throughout the app.
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Primary color (slightly lighter indigo)
  static const Color primaryColor = Color.fromARGB(255, 101, 121, 240);

  /// Sticky header background color for light mode (very light purple/gray)
  static const Color stickyHeaderColorLight = Color(0xFFF3E5F5);

  /// Sticky header background color for dark mode (very dark gray)
  static const Color stickyHeaderColorDark = Color(0xFF1E1E1E);

  /// Light theme configuration
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    // Seed-based color scheme generating the full Material Design palette
    // with auto-optimized contrast for light and dark modes.
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    // Additional styling can be added here as needed
  );

  /// Dark theme configuration
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    // Additional styling can be added here as needed
  );

  /// Gets the appropriate sticky header background color based on current theme
  static Color getStickyHeaderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? stickyHeaderColorLight
        : stickyHeaderColorDark;
  }
}

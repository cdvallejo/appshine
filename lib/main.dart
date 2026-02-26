import 'package:appshine/auth_gate.dart';
import 'package:appshine/firebase_options.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Initializes and runs the Appshine application.
///
/// This function:
/// 1. Ensures Flutter bindings are initialized
/// 2. Sets up Firebase with platform-specific options
/// 3. Loads environment variables from .env file
/// 4. Runs the [MainApp] root widget
///
/// Must be called as the entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  runApp(const MainApp());
}

/// Root widget of the Appshine application.
///
/// Manages localization state and provides the ability to change the app's
/// locale dynamically via [setLocale]. This is a [StatefulWidget] to support
/// rebuilding the entire app when the language changes.
///
/// The [setLocale] static method can be called from any [BuildContext] to
/// change the application language at runtime.
///
/// See also:
/// * [_MainAppState], which manages the locale and provides the UI
class MainApp extends StatefulWidget {
  /// Creates a [MainApp] widget.
  const MainApp({super.key});

  /// Changes the application locale dynamically.
  ///
  /// This method finds the nearest [_MainAppState] ancestor and updates its
  /// [_locale] field, triggering a rebuild of the entire application with
  /// the new locale.
  ///
  /// Parameters:
  /// * [context]: The [BuildContext] used to find the [_MainAppState]
  /// * [newLocale]: The new [Locale] to apply (e.g., `Locale('es')`)
  ///
  /// Example:
  /// ```dart
  /// MainApp.setLocale(context, Locale('en'));
  /// ```
  static void setLocale(BuildContext context, Locale newLocale) {
    var state = context.findAncestorStateOfType<_MainAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MainApp> createState() => _MainAppState();
}

/// State for [MainApp].
///
/// Manages the current locale and provides localization delegates to support
/// Spanish and English languages. Rebuilds the Material app when the locale
/// changes, ensuring all localized strings and widgets reflect the new language.
class _MainAppState extends State<MainApp> {
  /// The current locale of the application.
  ///
  /// Defaults to Spanish (`Locale('es')`). This locale is passed to
  /// [MaterialApp] and affects the localization of all widgets.
  Locale _locale = const Locale('es');

  /// Updates the application locale.
  ///
  /// Calls [setState] to trigger a rebuild of the [MaterialApp] with the
  /// new locale, which propagates to all child widgets.
  ///
  /// Parameters:
  /// * [locale]: The new [Locale] to set
  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  /// Builds the [MaterialApp] with localization support.
  ///
  /// Configures:
  /// * **Localization**: Supports Spanish and English via custom and built-in delegates
  /// * **Home**: Displays [AuthGate] to handle authentication state
  ///
  /// The localization delegates are applied in order:
  /// 1. [AppLocalizationsDelegate] - Custom translations for the app
  /// 2. [GlobalMaterialLocalizations.delegate] - Material Design text (buttons, dialogs)
  /// 3. [GlobalCupertinoLocalizations.delegate] - iOS Cupertino style text
  /// 4. [GlobalWidgetsLocalizations.delegate] - Framework-level text
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      home: const AuthGate(),
    );
  }
}
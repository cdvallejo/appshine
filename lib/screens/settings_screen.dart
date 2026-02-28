import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appshine/l10n/app_localizations.dart';
import 'package:appshine/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Currently selected language code ('en' or 'es')
  late String _selectedLanguage;

  /// Whether dark mode is enabled
  late bool _darkModeEnabled;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    // Update selected language from context
    _selectedLanguage = loc.locale.languageCode;
    
    // Sync dark mode state with current theme
    _darkModeEnabled = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: ListView(
        children: [
          // LANGUAGE SECTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.translate('language'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: _selectedLanguage,
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                      MainApp.setLocale(context, Locale(value));
                    }
                  },
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(loc.translate('spanish')),
                        leading: Radio<String>(value: 'es'),
                      ),
                      ListTile(
                        title: Text(loc.translate('english')),
                        leading: Radio<String>(value: 'en'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // DARK MODE SECTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.translate('theme'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(loc.translate('darkMode')),
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    MainApp.setThemeMode(
                      context,
                      value ? ThemeMode.dark : ThemeMode.light,
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // INSIGHTS SECTION (TODO: future implementation)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListTile(
              leading: Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
              title: Text(loc.translate('insights')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Navigate to insights screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('insightsComing'))),
                );
              },
            ),
          ),

          const Divider(height: 32),

          // LOGOUT SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: Text(loc.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(loc.translate('closeSessionTitle')),
                    content: Text(loc.translate('closeSessionMessage')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Close settings screen
                          }
                        },
                        child: Text(
                          loc.translate('closeSessionTitle'),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Current language selected. 'es' for Spanish, 'en' for English
  String _selectedLanguage = 'en';

  /// Whether dark mode is enabled
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // LANGUAGE SECTION
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LANGUAGE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: _selectedLanguage,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedLanguage = value ?? 'en';
                    });
                    // TODO: Change app language logic here
                  },
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Spanish'),
                        leading: Radio<String>(value: 'es'),
                      ),
                      ListTile(
                        title: const Text('English'),
                        leading: Radio<String>(value: 'en'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // DARK MODE SECTION (TODO: future implementation)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THEME',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    // TODO: Implement dark mode logic
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
              leading: const Icon(Icons.bar_chart, color: Colors.indigo),
              title: const Text('Insights'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: Navigate to insights screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insights - Coming soon')),
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
              label: const Text('Cerrar sesión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Close session'),
                    content: const Text('Are you sure you want to close the session?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Close settings screen
                          }
                        },
                        child: const Text('Close session', style: TextStyle(color: Colors.red)),
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

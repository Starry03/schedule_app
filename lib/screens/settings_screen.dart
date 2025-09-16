import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Impostazioni', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),

              // Preferences first: include dark mode and scheduling preferences
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tune),
                      title: const Text('Preferences'),
                      subtitle: const Text('Configure UI and scheduling preferences'),
                    ),

                    // Dark Mode inside Preferences
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Switch between light and dark theme'),
                      value: themeProvider.isDark(context),
                      onChanged: (value) {
                        themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),

                    // Contrast between days (columns) - softened label
                    SwitchListTile(
                      title: const Text('Sfumatura tra i giorni'),
                      subtitle: const Text('Leggera sfumatura per distinguere i giorni (colonne)'),
                      value: settingsProvider.highContrast,
                      onChanged: (v) => settingsProvider.setHighContrast(v),
                    ),

                    // Max variable hours (1..6)
                    ListTile(
                      title: const Text('Max variable hours per teacher'),
                      subtitle: Text('Current: ${settingsProvider.maxVariableHours}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final result = await showDialog<int>(
                          context: context,
                          builder: (ctx) {
                            int temp = settingsProvider.maxVariableHours.clamp(1, 6).toInt();
                            return AlertDialog(
                              title: const Text('Set max variable hours'),
                              content: StatefulBuilder(
                                builder: (c, setState) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Current: ${settingsProvider.maxVariableHours}'),
                                      Slider(
                                        min: 1,
                                        max: 6,
                                        divisions: 5,
                                        value: temp.toDouble(),
                                        label: temp.toString(),
                                        onChanged: (d) => setState(() => temp = d.toInt()),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.of(ctx).pop(temp), child: const Text('OK')),
                              ],
                            );
                          },
                        );
                        if (result != null) {
                          await settingsProvider.setMaxVariableHours(result.clamp(1, 6).toInt());
                        }
                      },
                    ),

                    // Auto 1-hour break
                    SwitchListTile(
                      title: const Text('Auto 1-hour break'),
                      subtitle: const Text('Enforce a 1-hour break when exceeding configured hours'),
                      value: settingsProvider.autoBreakEnabled,
                      onChanged: (v) => settingsProvider.setAutoBreakEnabled(v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: const Text('Logout'),
                  subtitle: const Text('Sign out of your account'),
                  onTap: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

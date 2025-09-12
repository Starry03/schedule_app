import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom header like home screen
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: themeProvider.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  value: themeProvider.isDark(context),
                  onChanged: (value) {
                    themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                  },
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

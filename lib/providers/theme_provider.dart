import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Start with system default
  static const String _themeModeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    // Don't load theme in constructor for better async control
  }

  // Initialize method to be called in main
  Future<void> initialize() async {
    await _loadThemeMode();
  }

  // Load theme mode from SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeModeKey);
      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  // Save theme mode to SharedPreferences
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  // Get the effective theme based on system brightness when system mode is selected
  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _saveThemeMode();
    notifyListeners();
  }

  // Centralized light theme used across the app
  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6), // Same violet as dark theme and gradient
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFFAFAFC),
      onSurface: const Color(0xFF0F172A),
      primary: const Color(0xFF8B5CF6),
      onPrimary: Colors.white,
      secondary: const Color(0xFF06B6D4),
      tertiary: const Color(0xFFFF6B6B),
      error: const Color(0xFFEF4444),
      outline: const Color(0xFFE2E8F0),
      surfaceContainer: const Color(0xFFF1F5F9),
      surfaceContainerHigh: Colors.white,
      surfaceContainerHighest: const Color(0xFFF8FAFC),
      primaryContainer: const Color(0xFFEEF2FF),
      onPrimaryContainer: const Color(0xFF4C1D95),
    );
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
        color: colorScheme.surfaceContainerHigh,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        toolbarTextStyle: TextStyle(color: colorScheme.onPrimary),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 6,
        backgroundColor: colorScheme.surface,
        titleTextStyle: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700),
        contentTextStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: colorScheme.onSurface)),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Shared gradient used by several screens to match the reference aesthetic
  LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
      );

  // Centralized dark theme used across the app
  // Centralized dark theme used across the app
  ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8B5CF6), // Beautiful purple
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF0F0F1A), // Deep dark blue
      onSurface: const Color(0xFFF1F5F9),
      primary: const Color(0xFF8B5CF6), // Vibrant purple
      onPrimary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFF06B6D4), // Bright cyan
      tertiary: const Color(0xFFEC4899), // Hot pink
      error: const Color(0xFFF87171),
      outline: const Color(0xFF475569),
      surfaceContainer: const Color(0xFF1E1B31), // Rich purple-tinted dark
      surfaceContainerHigh: const Color(0xFF2D2A44), // Deeper purple-tinted
      surfaceContainerHighest: const Color(0xFF3C3856), // Even deeper
      primaryContainer: const Color(0xFF5B21B6), // Deep purple container
      onPrimaryContainer: const Color(0xFFDDD6FE), // Light purple text
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
        color: colorScheme.surfaceContainerHigh,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: colorScheme.onSurface),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kHighContrast = 'prefs_high_contrast';
  static const _kMaxVariableHours = 'prefs_max_variable_hours';
  static const _kAutoBreakEnabled = 'prefs_auto_break_enabled';

  bool _highContrast = false;
  int _maxVariableHours = 6;
  bool _autoBreakEnabled = false;

  bool get highContrast => _highContrast;
  int get maxVariableHours => _maxVariableHours;
  bool get autoBreakEnabled => _autoBreakEnabled;

  SettingsProvider() {
    // load asynchronously, notify when ready
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _highContrast = prefs.getBool(_kHighContrast) ?? _highContrast;
      _maxVariableHours = prefs.getInt(_kMaxVariableHours) ?? _maxVariableHours;
      _autoBreakEnabled = prefs.getBool(_kAutoBreakEnabled) ?? _autoBreakEnabled;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('SettingsProvider: failed to load prefs: $e');
      }
    }
  }

  Future<void> setHighContrast(bool v) async {
    _highContrast = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHighContrast, v);
  }

  Future<void> setMaxVariableHours(int v) async {
    _maxVariableHours = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kMaxVariableHours, v);
  }

  Future<void> setAutoBreakEnabled(bool v) async {
    _autoBreakEnabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoBreakEnabled, v);
  }
}

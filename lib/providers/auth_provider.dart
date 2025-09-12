import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Check if user has existing session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _user = session.user;
    } else {
      // Try to restore from stored credentials
      await _restoreSession();
    }
    
    _isInitialized = true;
    notifyListeners();
    
    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((event) async {
      _user = event.session?.user;
      
      if (event.session != null) {
        // Save session to local storage
        await _saveSession(event.session!);
      } else {
        // Clear stored session
        await _clearSession();
      }
      
      notifyListeners();
    });
  }

  Future<void> _saveSession(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', session.accessToken);
    await prefs.setString('refresh_token', session.refreshToken ?? '');
    await prefs.setInt('expires_at', session.expiresAt ?? 0);
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final expiresAt = prefs.getInt('expires_at');

      if (accessToken != null && refreshToken != null && expiresAt != null) {
        // Check if token is still valid
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (expiresAt > now) {
          // Try to restore session
          await _supabase.auth.setSession(accessToken);
        } else {
          // Token expired, try to refresh
          await _supabase.auth.refreshSession(refreshToken);
        }
      }
    } catch (e) {
      // If restoration fails, clear stored data
      await _clearSession();
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('expires_at');
  }

  Future<void> signIn(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _clearSession();
  }
}

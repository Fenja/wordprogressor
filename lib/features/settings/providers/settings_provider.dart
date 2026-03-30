import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme ─────────────────────────────────────────────────────────────────

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // Default: follow system
  return ThemeMode.system;
});

// Persist theme mode to SharedPreferences
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs)
      : super(_loadTheme(_prefs));

  static ThemeMode _loadTheme(SharedPreferences prefs) {
    final saved = prefs.getString('theme_mode');
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void set(ThemeMode mode) {
    state = mode;
    _prefs.setString('theme_mode', mode.name);
  }
}

// ── Notifications ─────────────────────────────────────────────────────────

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

// ── Sync ──────────────────────────────────────────────────────────────────

final syncEnabledProvider = StateProvider<bool>((ref) => false);

// ── Auth ──────────────────────────────────────────────────────────────────

final isLoggedInProvider = StateProvider<bool>((ref) => false);

// ── Shared Preferences ────────────────────────────────────────────────────

final sharedPreferencesProvider =
FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});
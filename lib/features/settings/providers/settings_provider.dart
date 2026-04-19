import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

export '../../../core/services/auth_service.dart'
    show authStateProvider, isLoggedInProvider, currentUserProvider;

// ── Theme ─────────────────────────────────────────────────────────────────────

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // Loaded from SharedPreferences asynchronously on first use.
  // Defaults to system while loading.
  return ThemeMode.system;
});

// ── Notifications ─────────────────────────────────────────────────────────────

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);

// ── Cloud Sync ────────────────────────────────────────────────────────────────

final syncEnabledProvider = StateProvider<bool>((ref) => false);

// ── Shared Preferences ────────────────────────────────────────────────────────

final sharedPreferencesProvider =
FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});
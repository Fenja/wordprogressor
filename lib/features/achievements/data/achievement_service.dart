import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/achievement_model.dart';

/// Persistence key in AppSettings table.
const _kSettingsKey = 'unlocked_achievements';

/// AchievementService handles:
///   1. Loading unlocked achievements from AppSettings (local SQLite).
///   2. Evaluating whether new achievements should unlock after events.
///   3. Persisting newly unlocked achievements.
///
/// All methods are pure Dart — no Flutter widgets.
class AchievementService {
  final AppDatabase _db;
  AchievementService(this._db);

  // ── Persistence ────────────────────────────────────────────────────────────

  /// Returns map of { achievementId → unlockedAt ISO-8601 string }.
  Future<Map<String, String>> _loadRaw() async {
    final raw = await _db.getSetting(_kSettingsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveRaw(Map<String, String> data) async {
    await _db.setSetting(_kSettingsKey, jsonEncode(data));
  }

  /// Returns all currently unlocked achievements with their unlock timestamps.
  Future<List<UnlockedAchievement>> loadUnlocked() async {
    final raw = await _loadRaw();
    final result = <UnlockedAchievement>[];
    for (final def in kAllAchievements) {
      if (raw.containsKey(def.id)) {
        final ts = DateTime.tryParse(raw[def.id]!) ?? DateTime.now();
        result.add(UnlockedAchievement(def: def, unlockedAt: ts));
      }
    }
    return result;
  }

  /// Returns IDs of all currently unlocked achievements.
  Future<Set<String>> loadUnlockedIds() async {
    final raw = await _loadRaw();
    return raw.keys.toSet();
  }

  /// Marks an achievement as unlocked now. No-op if already unlocked.
  /// Returns true if this was a new unlock.
  Future<bool> unlock(String id) async {
    final raw = await _loadRaw();
    if (raw.containsKey(id)) return false; // already unlocked
    raw[id] = DateTime.now().toIso8601String();
    await _saveRaw(raw);
    return true;
  }

  // ── Evaluation ─────────────────────────────────────────────────────────────
  // Call these after the relevant event. Each returns the list of
  // newly unlocked AchievementDef objects (empty list = nothing new).

  /// Call after every logSession().
  /// Pass the total cumulative word count across all projects,
  /// the current streak in days, and the session that was just saved.
  Future<List<AchievementDef>> evaluateAfterSession({
    required int totalWordsAllProjects,
    required int currentStreakDays,
    required int sessionWords,
    required int sessionDurationMinutes,
    required DateTime sessionTime,
  }) async {
    final unlocked = await loadUnlockedIds();
    final newlyUnlocked = <AchievementDef>[];

    Future<void> tryUnlock(AchievementDef def) async {
      if (unlocked.contains(def.id)) return;
      final isNew = await unlock(def.id);
      if (isNew) newlyUnlocked.add(def);
    }

    // First session ever
    if (!unlocked.contains(AchievementId.firstSession)) {
      await tryUnlock(_def(AchievementId.firstSession));
    }

    // Word milestones
    for (final def in kAllAchievements.where(
        (d) => d.category == AchievementCategory.words && d.threshold != null)) {
      if (totalWordsAllProjects >= def.threshold!) await tryUnlock(def);
    }

    // Streak milestones
    for (final def in kAllAchievements.where(
        (d) => d.category == AchievementCategory.streak && d.threshold != null)) {
      if (currentStreakDays >= def.threshold!) await tryUnlock(def);
    }

    // Bonus: Night owl (session after 22:00)
    if (sessionTime.hour >= 22) await tryUnlock(_def(AchievementId.nightOwl));

    // Bonus: Early bird (session before 06:00)
    if (sessionTime.hour < 6) await tryUnlock(_def(AchievementId.earlyBird));

    // Bonus: Marathon (5.000 words in one session)
    if (sessionWords >= 5000) await tryUnlock(_def(AchievementId.marathon));

    // Bonus: Speedwriter (1.000 words in < 30 min)
    if (sessionWords >= 1000 &&
        sessionDurationMinutes > 0 &&
        sessionDurationMinutes < 30) {
      await tryUnlock(_def(AchievementId.speedwriter));
    }

    return newlyUnlocked;
  }

  /// Call after a project's status changes to 'submitted'.
  /// Pass the total number of completed projects (including the current one).
  Future<List<AchievementDef>> evaluateAfterProjectCompleted({
    required int totalCompletedProjects,
  }) async {
    final newlyUnlocked = <AchievementDef>[];

    for (final def in kAllAchievements.where(
        (d) => d.category == AchievementCategory.projects && d.threshold != null)) {
      if (totalCompletedProjects >= def.threshold!) {
        final isNew = await unlock(def.id);
        if (isNew) newlyUnlocked.add(def);
      }
    }

    return newlyUnlocked;
  }

  // ── Streak Calculation ────────────────────────────────────────────────────

  /// Calculates the current writing streak from session dates.
  /// A streak is consecutive calendar days (today or yesterday counts).
  static int calculateStreak(List<DateTime> sessionDates) {
    if (sessionDates.isEmpty) return 0;

    // Normalise to date-only, deduplicate, sort descending
    final days = sessionDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final yesterdayNorm = todayNorm.subtract(const Duration(days: 1));

    // Streak must start today or yesterday
    if (days.first != todayNorm && days.first != yesterdayNorm) return 0;

    int streak = 1;
    for (var i = 1; i < days.length; i++) {
      final expected = days[i - 1].subtract(const Duration(days: 1));
      if (days[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  static AchievementDef _def(String id) =>
      kAllAchievements.firstWhere((d) => d.id == id);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(ref.watch(appDatabaseProvider));
});

final unlockedAchievementsProvider =
    FutureProvider<List<UnlockedAchievement>>((ref) {
  return ref.watch(achievementServiceProvider).loadUnlocked();
});

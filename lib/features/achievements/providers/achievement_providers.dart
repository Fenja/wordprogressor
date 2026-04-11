import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';
import '../data/achievement_service.dart';
import '../domain/achievement_model.dart';

// Re-export the provider already declared in achievement_service.dart
// so UI can import from one place.
export '../data/achievement_service.dart'
    show unlockedAchievementsProvider, achievementServiceProvider;

part 'achievement_providers.g.dart';

/// Current writing streak (consecutive days).
@riverpod
Future<int> currentStreak(CurrentStreakRef ref) async {
  final db = ref.watch(appDatabaseProvider);
  final sessions = await db.getSessionsInRange(
    DateTime.now().subtract(const Duration(days: 400)),
    DateTime.now(),
  );
  return AchievementService.calculateStreak(
    sessions.map((s) => s.sessionDate).toList(),
  );
}

/// All achievements grouped into unlocked / locked.
@riverpod
Future<AchievementProgress> achievementProgress(
    AchievementProgressRef ref) async {
  final unlocked = await ref.watch(unlockedAchievementsProvider.future);
  final unlockedIds = unlocked.map((u) => u.def.id).toSet();

  final locked = kAllAchievements
      .where((d) => !unlockedIds.contains(d.id))
      .toList();

  return AchievementProgress(
    unlocked: unlocked,
    locked: locked,
    totalPoints: unlocked.fold(0, (s, u) => s + _points(u.def.tier)),
    maxPoints: kAllAchievements.fold(0, (s, d) => s + _points(d.tier)),
  );
}

int _points(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:   return 10;
    case AchievementTier.silver:   return 25;
    case AchievementTier.gold:     return 50;
    case AchievementTier.platinum: return 100;
  }
}

class AchievementProgress {
  final List<UnlockedAchievement> unlocked;
  final List<AchievementDef> locked;
  final int totalPoints;
  final int maxPoints;

  const AchievementProgress({
    required this.unlocked,
    required this.locked,
    required this.totalPoints,
    required this.maxPoints,
  });

  double get percent =>
      maxPoints > 0 ? (totalPoints / maxPoints).clamp(0.0, 1.0) : 0.0;

  int get unlockedCount => unlocked.length;
  int get totalCount => unlocked.length + locked.length;
}

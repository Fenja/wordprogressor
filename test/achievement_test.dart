import 'package:flutter_test/flutter_test.dart';
import 'package:wordprogressor/features/achievements/data/achievement_service.dart';
import 'package:wordprogressor/features/achievements/domain/achievement_model.dart';

void main() {
  // ── Streak calculation ────────────────────────────────────────────────────

  group('AchievementService.calculateStreak', () {
    DateTime day(int daysAgo) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: daysAgo));
    }

    test('empty list returns 0', () {
      expect(AchievementService.calculateStreak([]), 0);
    });

    test('only today returns 1', () {
      expect(AchievementService.calculateStreak([day(0)]), 1);
    });

    test('only yesterday returns 1', () {
      expect(AchievementService.calculateStreak([day(1)]), 1);
    });

    test('two days ago alone returns 0 (streak broken)', () {
      expect(AchievementService.calculateStreak([day(2)]), 0);
    });

    test('today + yesterday = streak 2', () {
      expect(
          AchievementService.calculateStreak([day(0), day(1)]), 2);
    });

    test('5 consecutive days ending today = streak 5', () {
      final sessions = List.generate(5, (i) => day(i));
      expect(AchievementService.calculateStreak(sessions), 5);
    });

    test('gap breaks the streak', () {
      // today, yesterday, 3 days ago (missing 2 days ago)
      final sessions = [day(0), day(1), day(3)];
      expect(AchievementService.calculateStreak(sessions), 2);
    });

    test('multiple sessions same day count as one', () {
      final sessions = [
        day(0),
        day(0), // duplicate
        day(1),
        day(2),
      ];
      expect(AchievementService.calculateStreak(sessions), 3);
    });

    test('7 day streak starting yesterday', () {
      final sessions = List.generate(7, (i) => day(i + 1)); // yesterday..7 days ago
      expect(AchievementService.calculateStreak(sessions), 7);
    });
  });

  // ── Achievement definitions ───────────────────────────────────────────────

  group('kAllAchievements completeness', () {
    test('all IDs are unique', () {
      final ids = kAllAchievements.map((d) => d.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate achievement ID found');
    });

    test('all word thresholds are in ascending order', () {
      final wordDefs = kAllAchievements
          .where((d) =>
              d.category == AchievementCategory.words && d.threshold != null)
          .map((d) => d.threshold!)
          .toList();
      for (var i = 1; i < wordDefs.length; i++) {
        expect(wordDefs[i] > wordDefs[i - 1], isTrue,
            reason: 'Word thresholds not in ascending order');
      }
    });

    test('all streak thresholds are in ascending order', () {
      final streakDefs = kAllAchievements
          .where((d) =>
              d.category == AchievementCategory.streak && d.threshold != null)
          .map((d) => d.threshold!)
          .toList();
      for (var i = 1; i < streakDefs.length; i++) {
        expect(streakDefs[i] > streakDefs[i - 1], isTrue,
            reason: 'Streak thresholds not in ascending order');
      }
    });

    test('all project thresholds are in ascending order', () {
      final projectDefs = kAllAchievements
          .where((d) =>
              d.category == AchievementCategory.projects &&
              d.threshold != null)
          .map((d) => d.threshold!)
          .toList();
      for (var i = 1; i < projectDefs.length; i++) {
        expect(projectDefs[i] > projectDefs[i - 1], isTrue);
      }
    });

    test('total achievement count is 24', () {
      expect(kAllAchievements.length, 24);
    });

    test('each tier has at least one achievement', () {
      for (final tier in AchievementTier.values) {
        expect(
          kAllAchievements.any((d) => d.tier == tier),
          isTrue,
          reason: 'No achievement found for tier ${tier.name}',
        );
      }
    });
  });

  // ── Point calculation ─────────────────────────────────────────────────────

  group('Achievement point values', () {
    int points(AchievementTier tier) {
      switch (tier) {
        case AchievementTier.bronze:   return 10;
        case AchievementTier.silver:   return 25;
        case AchievementTier.gold:     return 50;
        case AchievementTier.platinum: return 100;
      }
    }

    test('max possible points is calculated correctly', () {
      final max = kAllAchievements.fold<int>(0, (s, d) => s + points(d.tier));
      // Sanity check: should be in a reasonable range
      expect(max, greaterThan(200));
      expect(max, lessThan(5000));
    });
  });
}

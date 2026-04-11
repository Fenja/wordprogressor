import 'package:flutter/material.dart';

// ─── Achievement IDs ────────────────────────────────────────────────────────
// Stable string IDs stored in AppSettings table as JSON.
// Never rename these — they are the persistence keys.

abstract class AchievementId {
  // Words written (cumulative across all projects)
  static const words1k      = 'words_1k';
  static const words10k     = 'words_10k';
  static const words50k     = 'words_50k';
  static const words100k    = 'words_100k';
  static const words250k    = 'words_250k';
  static const words500k    = 'words_500k';
  static const words1m      = 'words_1m';

  // Writing streak (consecutive days with at least one session)
  static const streak3      = 'streak_3';
  static const streak7      = 'streak_7';
  static const streak14     = 'streak_14';
  static const streak30     = 'streak_30';
  static const streak100    = 'streak_100';
  static const streak365    = 'streak_365';

  // Projects completed (status == submitted)
  static const projects1    = 'projects_1';
  static const projects3    = 'projects_3';
  static const projects5    = 'projects_5';
  static const projects10   = 'projects_10';
  static const projects25   = 'projects_25';

  // Bonus achievements
  static const firstSession = 'first_session';   // erste Schreibsitzung
  static const nightOwl     = 'night_owl';        // Session nach 22 Uhr
  static const earlyBird    = 'early_bird';       // Session vor 6 Uhr
  static const marathon     = 'marathon';          // 5.000 Wörter in einer Sitzung
  static const speedwriter  = 'speedwriter';      // 1.000 Wörter in < 30 Min.
  static const perfectMonth = 'perfect_month';    // 30 Tage Streak in einem Kalendermonat
}

// ─── Achievement Category ────────────────────────────────────────────────────

enum AchievementCategory {
  words,
  streak,
  projects,
  bonus;

  String get label {
    switch (this) {
      case AchievementCategory.words:    return 'Wörter';
      case AchievementCategory.streak:   return 'Schreibstreak';
      case AchievementCategory.projects: return 'Projekte';
      case AchievementCategory.bonus:    return 'Besonderes';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementCategory.words:    return Icons.article_outlined;
      case AchievementCategory.streak:   return Icons.local_fire_department_outlined;
      case AchievementCategory.projects: return Icons.check_circle_outline_rounded;
      case AchievementCategory.bonus:    return Icons.star_outline_rounded;
    }
  }
}

// ─── Achievement Tier (for visual distinction) ───────────────────────────────

enum AchievementTier { bronze, silver, gold, platinum }

// ─── Achievement Definition ──────────────────────────────────────────────────

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final AchievementTier tier;

  /// Progress value this achievement unlocks at (words / days / projects).
  /// null for one-off bonus achievements.
  final int? threshold;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.tier,
    this.threshold,
  });
}

// ─── All Achievement Definitions ─────────────────────────────────────────────

const kAllAchievements = <AchievementDef>[
  // ── Words ──────────────────────────────────────────────────────────────────
  AchievementDef(
    id: AchievementId.words1k,
    title: 'Erste Schritte',
    description: '1.000 Wörter geschrieben',
    emoji: '✏️',
    category: AchievementCategory.words,
    tier: AchievementTier.bronze,
    threshold: 1000,
  ),
  AchievementDef(
    id: AchievementId.words10k,
    title: 'Zehntausender',
    description: '10.000 Wörter geschrieben',
    emoji: '📝',
    category: AchievementCategory.words,
    tier: AchievementTier.bronze,
    threshold: 10000,
  ),
  AchievementDef(
    id: AchievementId.words50k,
    title: 'NaNoWriMo',
    description: '50.000 Wörter geschrieben',
    emoji: '📖',
    category: AchievementCategory.words,
    tier: AchievementTier.silver,
    threshold: 50000,
  ),
  AchievementDef(
    id: AchievementId.words100k,
    title: 'Romanautor',
    description: '100.000 Wörter geschrieben',
    emoji: '📚',
    category: AchievementCategory.words,
    tier: AchievementTier.silver,
    threshold: 100000,
  ),
  AchievementDef(
    id: AchievementId.words250k,
    title: 'Viertelmeister',
    description: '250.000 Wörter geschrieben',
    emoji: '🖊️',
    category: AchievementCategory.words,
    tier: AchievementTier.gold,
    threshold: 250000,
  ),
  AchievementDef(
    id: AchievementId.words500k,
    title: 'Halbmillion',
    description: '500.000 Wörter geschrieben',
    emoji: '🏆',
    category: AchievementCategory.words,
    tier: AchievementTier.gold,
    threshold: 500000,
  ),
  AchievementDef(
    id: AchievementId.words1m,
    title: 'Millionär der Worte',
    description: '1.000.000 Wörter geschrieben',
    emoji: '👑',
    category: AchievementCategory.words,
    tier: AchievementTier.platinum,
    threshold: 1000000,
  ),

  // ── Streak ─────────────────────────────────────────────────────────────────
  AchievementDef(
    id: AchievementId.streak3,
    title: 'Dranbleiben',
    description: '3 Tage in Folge geschrieben',
    emoji: '🔥',
    category: AchievementCategory.streak,
    tier: AchievementTier.bronze,
    threshold: 3,
  ),
  AchievementDef(
    id: AchievementId.streak7,
    title: 'Eine Woche Feuer',
    description: '7 Tage in Folge geschrieben',
    emoji: '🌟',
    category: AchievementCategory.streak,
    tier: AchievementTier.bronze,
    threshold: 7,
  ),
  AchievementDef(
    id: AchievementId.streak14,
    title: 'Zwei Wochen stark',
    description: '14 Tage in Folge geschrieben',
    emoji: '⚡',
    category: AchievementCategory.streak,
    tier: AchievementTier.silver,
    threshold: 14,
  ),
  AchievementDef(
    id: AchievementId.streak30,
    title: 'Ein Monat Disziplin',
    description: '30 Tage in Folge geschrieben',
    emoji: '💎',
    category: AchievementCategory.streak,
    tier: AchievementTier.silver,
    threshold: 30,
  ),
  AchievementDef(
    id: AchievementId.streak100,
    title: 'Hundert Tage',
    description: '100 Tage in Folge geschrieben',
    emoji: '🌠',
    category: AchievementCategory.streak,
    tier: AchievementTier.gold,
    threshold: 100,
  ),
  AchievementDef(
    id: AchievementId.streak365,
    title: 'Ein ganzes Jahr',
    description: '365 Tage in Folge geschrieben',
    emoji: '🎖️',
    category: AchievementCategory.streak,
    tier: AchievementTier.platinum,
    threshold: 365,
  ),

  // ── Projects ───────────────────────────────────────────────────────────────
  AchievementDef(
    id: AchievementId.projects1,
    title: 'Fertiggestellt',
    description: '1 Projekt eingereicht',
    emoji: '✅',
    category: AchievementCategory.projects,
    tier: AchievementTier.bronze,
    threshold: 1,
  ),
  AchievementDef(
    id: AchievementId.projects3,
    title: 'Trilogie',
    description: '3 Projekte eingereicht',
    emoji: '📗',
    category: AchievementCategory.projects,
    tier: AchievementTier.bronze,
    threshold: 3,
  ),
  AchievementDef(
    id: AchievementId.projects5,
    title: 'Fünffach',
    description: '5 Projekte eingereicht',
    emoji: '📘',
    category: AchievementCategory.projects,
    tier: AchievementTier.silver,
    threshold: 5,
  ),
  AchievementDef(
    id: AchievementId.projects10,
    title: 'Prolific',
    description: '10 Projekte eingereicht',
    emoji: '📙',
    category: AchievementCategory.projects,
    tier: AchievementTier.gold,
    threshold: 10,
  ),
  AchievementDef(
    id: AchievementId.projects25,
    title: 'Lebenswerk',
    description: '25 Projekte eingereicht',
    emoji: '🏛️',
    category: AchievementCategory.projects,
    tier: AchievementTier.platinum,
    threshold: 25,
  ),

  // ── Bonus ──────────────────────────────────────────────────────────────────
  AchievementDef(
    id: AchievementId.firstSession,
    title: 'Der erste Satz',
    description: 'Erste Schreibsitzung erfasst',
    emoji: '🌱',
    category: AchievementCategory.bonus,
    tier: AchievementTier.bronze,
  ),
  AchievementDef(
    id: AchievementId.nightOwl,
    title: 'Nachteule',
    description: 'Nach 22 Uhr geschrieben',
    emoji: '🦉',
    category: AchievementCategory.bonus,
    tier: AchievementTier.bronze,
  ),
  AchievementDef(
    id: AchievementId.earlyBird,
    title: 'Frühaufsteher',
    description: 'Vor 6 Uhr geschrieben',
    emoji: '🐦',
    category: AchievementCategory.bonus,
    tier: AchievementTier.bronze,
  ),
  AchievementDef(
    id: AchievementId.marathon,
    title: 'Marathonschreiber',
    description: '5.000 Wörter in einer Sitzung',
    emoji: '🏃',
    category: AchievementCategory.bonus,
    tier: AchievementTier.gold,
  ),
  AchievementDef(
    id: AchievementId.speedwriter,
    title: 'Schnellschreiber',
    description: '1.000 Wörter in unter 30 Minuten',
    emoji: '⚡',
    category: AchievementCategory.bonus,
    tier: AchievementTier.silver,
  ),
  AchievementDef(
    id: AchievementId.perfectMonth,
    title: 'Perfekter Monat',
    description: '30 Tage Streak in einem Kalendermonat',
    emoji: '📅',
    category: AchievementCategory.bonus,
    tier: AchievementTier.gold,
  ),
];

// ─── Unlocked Achievement (runtime model) ────────────────────────────────────

class UnlockedAchievement {
  final AchievementDef def;
  final DateTime unlockedAt;

  const UnlockedAchievement({required this.def, required this.unlockedAt});
}

// ─── Tier visual helpers ──────────────────────────────────────────────────────

extension AchievementTierX on AchievementTier {
  Color borderColor(Brightness brightness) {
    switch (this) {
      case AchievementTier.bronze:   return const Color(0xFFCD7F32);
      case AchievementTier.silver:   return const Color(0xFFA8A9AD);
      case AchievementTier.gold:     return const Color(0xFFFFD700);
      case AchievementTier.platinum: return const Color(0xFF74C0FC);
    }
  }

  Color bgColor(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (this) {
      case AchievementTier.bronze:
        return dark ? const Color(0xFF2A1A0A) : const Color(0xFFFFF3E0);
      case AchievementTier.silver:
        return dark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
      case AchievementTier.gold:
        return dark ? const Color(0xFF2A2400) : const Color(0xFFFFFDE7);
      case AchievementTier.platinum:
        return dark ? const Color(0xFF0A1A2A) : const Color(0xFFE3F2FD);
    }
  }

  String get label {
    switch (this) {
      case AchievementTier.bronze:   return 'Bronze';
      case AchievementTier.silver:   return 'Silber';
      case AchievementTier.gold:     return 'Gold';
      case AchievementTier.platinum: return 'Platin';
    }
  }
}

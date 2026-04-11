import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/providers/project_providers.dart';
import '../../projects/domain/project_model.dart';
import '../data/achievement_service.dart';
import '../providers/achievement_providers.dart';
import '../domain/achievement_model.dart';
import './widgets/achievement_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);
    final projectsAsync = ref.watch(allProjectsProvider);
    final streakAsync = ref.watch(currentStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          // Points badge
          unlockedAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (unlocked) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Text('⭐', style: TextStyle(fontSize: 12)),
                label: Text(
                  '${_calcPoints(unlocked)} Pkt.',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: unlockedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (unlocked) {
          /*if (unlocked.isEmpty) {
            return Text('Noch keine Achievements freigeschaltet');
          }*/
          final unlockedMap = {
            for (final u in unlocked) u.def.id: u.unlockedAt
          };

          return CustomScrollView(
            slivers: [
              // Summary header
              SliverToBoxAdapter(
                child: _SummaryHeader(
                  unlocked: unlocked,
                  total: kAllAchievements.length,
                  projectsAsync: projectsAsync,
                  streakAsync: streakAsync,
                ),
              ),

              // Category sections
              for (final category in AchievementCategory.values) ...[
                SliverToBoxAdapter(
                  child: _CategoryHeader(category: category, unlockedMap: unlockedMap),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }

  int _calcPoints(List<UnlockedAchievement> unlocked) {
    return unlocked.fold(0, (sum, u) {
      switch (u.def.tier) {
        case AchievementTier.bronze:   return sum + 10;
        case AchievementTier.silver:   return sum + 25;
        case AchievementTier.gold:     return sum + 50;
        case AchievementTier.platinum: return sum + 100;
      }
    });
  }
}

// ── Summary Header ────────────────────────────────────────────────────────────

class _SummaryHeader extends ConsumerWidget {
  final List<UnlockedAchievement> unlocked;
  final int total;
  final AsyncValue<List<ProjectModel>> projectsAsync;
  final AsyncValue<int> streakAsync;

  const _SummaryHeader({
    required this.unlocked,
    required this.total,
    required this.projectsAsync,
    required this.streakAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pct = total > 0 ? unlocked.length / total : 0.0;
    final completedProjects = projectsAsync.value
            ?.where((p) => p.status == ProjectStatus.submitted)
            .length ??
        0;
    final totalWords = projectsAsync.value
            ?.fold<int>(0, (s, p) => s + p.wordCountCurrent) ??
        0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${unlocked.length} / $total',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Achievements freigeschaltet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Tier distribution
              _TierDistribution(unlocked: unlocked),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label:
                'Fortschritt: ${(pct * 100).round()} Prozent der Achievements freigeschaltet',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _StatPill(
                emoji: '📝',
                label: '${_fmt(totalWords)} Wörter',
              ),
              const SizedBox(width: 8),
              _StatPill(
                emoji: '✅',
                label: '$completedProjects Projekte',
              ),
              const SizedBox(width: 8),
              streakAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (streak) => streak > 0
                    ? _StatPill(
                        emoji: '🔥',
                        label: '$streak Tage Streak',
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} Mio.';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} Tsd.';
    return n.toString();
  }
}

class _TierDistribution extends StatelessWidget {
  final List<UnlockedAchievement> unlocked;
  const _TierDistribution({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final counts = {
      for (final tier in AchievementTier.values)
        tier: unlocked.where((u) => u.def.tier == tier).length,
    };

    return Row(
      children: AchievementTier.values.map((tier) {
        final count = counts[tier] ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tier.bgColor(brightness),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: tier.borderColor(brightness), width: 1.5),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tier.borderColor(brightness),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(tier.label,
                  style: const TextStyle(fontSize: 8)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji;
  final String label;
  const _StatPill({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Category Header ───────────────────────────────────────────────────────────

class _CategoryHeader extends StatelessWidget {
  final AchievementCategory category;
  final Map<String, DateTime> unlockedMap;

  const _CategoryHeader(
      {required this.category, required this.unlockedMap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defs =
        kAllAchievements.where((d) => d.category == category).toList();
    final unlockedCount =
        defs.where((d) => unlockedMap.containsKey(d.id)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Icon(category.icon,
              size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            category.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '$unlockedCount / ${defs.length}',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Grid ─────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final AchievementCategory category;
  final Map<String, DateTime> unlockedMap;

  const _CategoryGrid(
      {required this.category, required this.unlockedMap});

  @override
  Widget build(BuildContext context) {
    final defs =
        kAllAchievements.where((d) => d.category == category).toList();

    // Sort: unlocked first (newest first), then locked
    final sorted = [
      ...defs
          .where((d) => unlockedMap.containsKey(d.id))
          .toList()
        ..sort((a, b) => unlockedMap[b.id]!.compareTo(unlockedMap[a.id]!)),
      ...defs.where((d) => !unlockedMap.containsKey(d.id)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final def = sorted[i];
        return AchievementCard(
          def: def,
          unlockedAt: unlockedMap[def.id],
        );
      },
    );
  }
}

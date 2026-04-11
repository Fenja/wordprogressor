import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/session_providers.dart';
import '../../../../shared/utils/app_format.dart';

/// Replaces the placeholder bar chart in project_detail_screen.dart.
/// Drop-in: use `WeeklyWritingChart(projectId: project.id)` in the detail screen.
class WeeklyWritingChart extends ConsumerWidget {
  final String projectId;
  const WeeklyWritingChart({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dataAsync =
        ref.watch(recentDailyWordsProvider(projectId, days: 7));
    final statsAsync = ref.watch(sessionStatsProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        statsAsync.when(
          loading: () => const SizedBox(height: 20),
          error: (_, __) => const SizedBox.shrink(),
          data: (stats) => Wrap(
            spacing: 16,
            children: [
              _StatPill(
                  label: 'Sitzungen', value: stats.sessionCount.toString()),
              _StatPill(
                  label: 'Gesamt',
                  value: AppFormat.wordCountCompact(stats.totalWords)),
              _StatPill(
                  label: 'Ø/Sitzung',
                  value: AppFormat.wordCountCompact(stats.avgWordsPerSession)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Letzte 7 Tage',
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        dataAsync.when(
          loading: () => const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
          data: (days) {
            final maxWords =
                days.fold<int>(0, (m, d) => d.words > m ? d.words : m);

            return SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((day) {
                  final fraction =
                      maxWords > 0 ? day.words / maxWords : 0.0;
                  final isToday = _isToday(day.date);
                  final dayLabel =
                      DateFormat('E', 'de').format(day.date).substring(0, 2);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Semantics(
                        label:
                            '$dayLabel: ${AppFormat.wordCount(day.words, withUnit: true)}',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (day.words > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  AppFormat.wordCountCompact(day.words),
                                  style: TextStyle(
                                    fontSize: 8,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: fraction.clamp(0.04, 1.0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeOut,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? theme.colorScheme.primary
                                        : day.words > 0
                                            ? theme.colorScheme.primary
                                                .withOpacity(0.55)
                                            : theme.colorScheme
                                                .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dayLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isToday
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isToday
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

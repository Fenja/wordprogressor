import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/domain/project_model.dart';
import '../../projects/providers/project_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(projectStatsProvider);
    final projectsAsync = ref.watch(allProjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiken')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary cards
            _SummaryGrid(stats: stats),
            const SizedBox(height: 24),

            // Genre breakdown
            projectsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (projects) => _GenreBreakdown(projects: projects),
            ),

            const SizedBox(height: 24),

            // Progress overview
            projectsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (projects) => _ProgressOverview(projects: projects),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final ProjectStats stats;
  const _SummaryGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Projekte gesamt', stats.totalProjects.toString(), Icons.folder_outlined),
      ('Aktiv', stats.activeProjects.toString(), Icons.edit_outlined),
      ('Eingereicht', stats.completedProjects.toString(), Icons.check_circle_outline),
      (
      'Wörter gesamt',
      _fmtWords(stats.totalWords),
      Icons.article_outlined
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: items.map((item) => _StatCard(
        label: item.$1,
        value: item.$2,
        icon: item.$3,
      )).toList(),
    );
  }

  String _fmtWords(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} Mio.';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} Tsd.';
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenreBreakdown extends StatelessWidget {
  final List<ProjectModel> projects;
  const _GenreBreakdown({required this.projects});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    // Count by genre
    final Map<String, int> genreCounts = {};
    for (final p in projects) {
      genreCounts[p.genre] = (genreCounts[p.genre] ?? 0) + 1;
    }
    final sorted = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nach Genre',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        ...sorted.map((entry) => _GenreRow(
          genre: entry.key,
          count: entry.value,
          total: projects.length,
        )),
      ],
    );
  }
}

class _GenreRow extends StatelessWidget {
  final String genre;
  final int count;
  final int total;
  const _GenreRow(
      {required this.genre, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = total > 0 ? count / total : 0.0;
    final icon = kGenreIcons[genre] ?? '📝';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              genre,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor:
                theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final List<ProjectModel> projects;
  const _ProgressOverview({required this.projects});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = projects
        .where((p) =>
    p.status == ProjectStatus.active ||
        p.status == ProjectStatus.draft)
        .toList()
      ..sort((a, b) => b.progressPercent.compareTo(a.progressPercent));

    if (active.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fortschritt aktiver Projekte',
            style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        ...active.map((p) => _ProgressRow(project: p)),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final ProjectModel project;
  const _ProgressRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (project.progressPercent * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: project.progressPercent,
              minHeight: 5,
              backgroundColor:
              theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/project_model.dart';
import '../providers/project_providers.dart';
import 'widgets/deadline_badge.dart';
import 'widgets/project_progress_bar.dart';
import '../../../shared/widgets/cover_image.dart';
import 'project_search_delegate.dart';
import '../../achievements/providers/achievement_providers.dart';
import '../../../shared/widgets/user_status_badge.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(filteredProjectsProvider);
    final filter = ref.watch(projectFilterProvider);
    final streakAsync = ref.watch(currentStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WordProgressor'),
        actions: [
          // User status — compact avatar/sign-in button
          const UserStatusBadge(compact: true),
          // Streak badge
          streakAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (streak) => streak >= 2
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                      avatar: const Text('🔥',
                          style: TextStyle(fontSize: 12)),
                      label: Text(
                        '$streak',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      // FIXME tooltip: '$streak Tage Schreibstreak',
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Projekte suchen',
            onPressed: () => showSearch(
              context: context,
              delegate: ProjectSearchDelegate(ref),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _FilterChips(current: filter),
        ),
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (projects) {
          if (projects.isEmpty) {
            return _EmptyState(
              filter: filter,
              onAdd: () => context.push('/projects/new'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: projects.length,
            itemBuilder: (context, i) => _ProjectCard(project: projects[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/projects/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Neues Projekt'),
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  final ProjectFilter current;
  const _FilterChips({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = [
      (ProjectFilter.all, 'Alle'),
      (ProjectFilter.active, 'Aktiv'),
      (ProjectFilter.completed, 'Eingereicht'),
      (ProjectFilter.paused, 'Pausiert'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: filters.map((f) {
          final selected = current == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f.$2),
              selected: selected,
              onSelected: (_) =>
                  ref.read(projectFilterProvider.notifier).state = f.$1,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Project card ──────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCover =
        project.coverLocalPath != null || project.coverRemoteUrl != null;

    return Semantics(
      label:
          '${project.title}, ${project.genre}, ${(project.progressPercent * 100).toStringAsFixed(0)} Prozent abgeschlossen',
      button: true,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/projects/${project.id}'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image ───────────────────────────────────────────
                CoverImage(
                  localPath: project.coverLocalPath,
                  remoteUrl: project.coverRemoteUrl,
                  width: 56,
                  height: 78,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(width: 12),

                // ── Content ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              project.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusBadge(status: project.status),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Genre + word count
                      Text(
                        '${project.genre} · '
                        '${_formatWordCount(project.wordCountCurrent)} Wörter',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),

                      // Progress bar
                      ProjectProgressBar(
                        value: project.progressPercent,
                        height: 4,
                        semanticLabel:
                            '${(project.progressPercent * 100).round()}% fertig',
                      ),
                      const SizedBox(height: 5),

                      // Stats row
                      Row(
                        children: [
                          Text(
                            '${(project.progressPercent * 100).round()}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          if (project.chapterCountTotal > 0) ...[
                            Text(
                              ' · Kap. ${project.chapterCountDone}/'
                              '${project.chapterCountTotal}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                          const Spacer(),
                          DeadlineBadge(project: project),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatWordCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)} Tsd.';
    }
    return count.toString();
  }
}

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _colors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  (Color, Color) _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (status) {
      case ProjectStatus.active:
        return (scheme.primary, scheme.primaryContainer);
      case ProjectStatus.draft:
        return (scheme.onSurfaceVariant, scheme.surfaceContainerHighest);
      case ProjectStatus.revision:
        return (Colors.amber.shade800, Colors.amber.shade50);
      case ProjectStatus.submitted:
        return (Colors.green.shade700, Colors.green.shade50);
      case ProjectStatus.published:
        return (Colors.blue.shade700, Colors.blue.shade50);
      case ProjectStatus.abandoned:
        return (scheme.onSurfaceVariant, scheme.surfaceContainerHighest);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final ProjectFilter filter;
  final VoidCallback onAdd;

  const _EmptyState({required this.filter, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✍️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              filter == ProjectFilter.all
                  ? 'Noch keine Projekte'
                  : 'Keine Projekte gefunden',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              filter == ProjectFilter.all
                  ? 'Erstelle dein erstes Schreibprojekt und behalte Fortschritt und Deadlines im Blick.'
                  : 'Passe den Filter an oder erstelle ein neues Projekt.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (filter == ProjectFilter.all) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Projekt erstellen'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

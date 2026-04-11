import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/project_model.dart';
import '../providers/project_providers.dart';
import '../data/project_repository.dart';
import '../presentation/widgets/deadline_badge.dart';
import '../presentation/widgets/project_progress_bar.dart';
import '../presentation/widgets/log_session_sheet.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));

    return projectAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Fehler')),
        body: Center(child: Text(e.toString())),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Projekt nicht gefunden.')),
          );
        }
        return _ProjectDetailView(project: project);
      },
    );
  }
}

class _ProjectDetailView extends ConsumerWidget {
  final ProjectModel project;
  const _ProjectDetailView({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd. MMMM yyyy', 'de');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Meilensteine',
            onPressed: () =>
                context.push('/projects/${project.id}/milestones'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Projekt bearbeiten',
            onPressed: () => context.push('/projects/${project.id}/edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress hero
            _ProgressHero(project: project),

            const Divider(),

            // Meta grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _MetaGrid(project: project, fmt: fmt),
            ),

            const Divider(),

            // Tags
            if (project.tags.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _TagsSection(tags: project.tags),
              ),
              const Divider(),
            ],

            // Synopsis
            if (project.synopsis?.isNotEmpty == true) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _TextSection(
                    label: 'Synopsis', text: project.synopsis!),
              ),
              const Divider(),
            ],

            // Notes
            if (project.notes?.isNotEmpty == true) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child:
                    _TextSection(label: 'Notizen', text: project.notes!),
              ),
              const Divider(),
            ],

            // Weekly writing bar chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _WeeklyStats(projectId: project.id),
            ),

            const Divider(),

            // Danger zone
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _DangerZone(project: project),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schreibsitzung'),
      ),
    );
  }

  void _showLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LogSessionSheet(projectId: project.id),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  final ProjectModel project;
  const _ProgressHero({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (project.progressPercent * 100).round();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$pct% abgeschlossen',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt(project.wordCountCurrent)} / ${_fmt(project.wordCountGoal)} Wörter',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              DeadlineBadge(project: project, large: true),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            label:
                'Fortschritt: $pct Prozent, ${_fmt(project.wordCountCurrent)} von ${_fmt(project.wordCountGoal)} Wörtern',
            child: ProjectProgressBar(
              value: project.progressPercent,
              height: 8,
              semanticLabel: '',
            ),
          ),
          if (project.chapterCountTotal > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Kapitel ${project.chapterCountDone} von ${project.chapterCountTotal} fertig',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(int n) {
    return NumberFormat('#,###', 'de').format(n);
  }
}

class _MetaGrid extends StatelessWidget {
  final ProjectModel project;
  final DateFormat fmt;
  const _MetaGrid({required this.project, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Genre', project.genre),
      ('Status', project.status.label),
      ('Sprache', project.language),
      ('Begonnen', fmt.format(project.startedAt)),
      if (project.targetAudience != null)
        ('Zielgruppe', project.targetAudience!),
      if (project.chapterCountTotal > 0)
        ('Kapitel', '${project.chapterCountDone}/${project.chapterCountTotal}'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) => _MetaChip(label: item.$1, value: item.$2)).toList(),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  final List<String> tags;
  const _TagsSection({required this.tags});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tags
              .map((t) => Chip(
                    label: Text(t),
                    labelStyle: const TextStyle(fontSize: 12),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  final String label;
  final String text;
  const _TextSection({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Text(text, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _WeeklyStats extends ConsumerWidget {
  final String projectId;
  const _WeeklyStats({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Shows last 7 days bar chart placeholder
    // Full implementation uses fl_chart with WritingSession data
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diese Woche',
            style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
              final heights = [0.9, 0.4, 0.7, 0.0, 0.2, 0.6, 0.3];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FractionallySizedBox(
                          heightFactor: heights[i],
                          child: Container(
                            decoration: BoxDecoration(
                              color: heights[i] > 0
                                  ? theme.colorScheme.primary.withOpacity(0.8)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(days[i],
                          style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DangerZone extends ConsumerWidget {
  final ProjectModel project;
  const _DangerZone({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktionen',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(context, ref),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Projekt löschen'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(
                color: Theme.of(context).colorScheme.errorContainer),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Projekt löschen?'),
        content: Text(
            '"${project.title}" wird dauerhaft gelöscht. Alle Meilensteine und Schreibsitzungen werden ebenfalls gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(projectRepositoryProvider).deleteProject(project.id);
      if (context.mounted) context.go('/projects');
    }
  }
}

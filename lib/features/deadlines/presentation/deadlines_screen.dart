import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../projects/domain/project_model.dart';
import '../../projects/providers/project_providers.dart';
import '../../projects/presentation/widgets/deadline_badge.dart';
import '../../projects/presentation/widgets/project_progress_bar.dart';

class DeadlinesScreen extends ConsumerWidget {
  const DeadlinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(allProjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Deadlines')),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (projects) {
          final withDeadline = projects
              .where((p) =>
                  p.deadline != null && p.status != ProjectStatus.submitted)
              .toList()
            ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

          if (withDeadline.isEmpty) {
            return _EmptyDeadlines();
          }

          final overdue =
              withDeadline.where((p) => p.deadlineStatus == DeadlineStatus.overdue).toList();
          final upcoming =
              withDeadline.where((p) => p.deadlineStatus != DeadlineStatus.overdue).toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 40, top: 8),
            children: [
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                    label: 'Überfällig (${overdue.length})',
                    color: Theme.of(context).colorScheme.error),
                ...overdue.map((p) => _DeadlineCard(project: p)),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(label: 'Bevorstehend'),
                ...upcoming.map((p) => _DeadlineCard(project: p)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color? color;
  const _SectionHeader({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final ProjectModel project;
  const _DeadlineCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('dd. MMMM yyyy', 'de');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/projects/${project.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(project.title,
                        style: theme.textTheme.titleSmall),
                  ),
                  DeadlineBadge(project: project),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${project.genre} · Fällig: ${fmt.format(project.deadline!)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              ProjectProgressBar(value: project.progressPercent),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(project.progressPercent * 100).round()}% fertig',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    '${NumberFormat('#,###', 'de').format(project.wordsRemaining)} Wörter verbleibend',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDeadlines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Keine Deadlines gesetzt',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Setze in deinen Projekten Deadlines, um sie hier zu verfolgen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

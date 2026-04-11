import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/project_model.dart';
import '../providers/project_providers.dart';
import 'widgets/deadline_badge.dart';
import 'widgets/project_progress_bar.dart';

class ProjectSearchDelegate extends SearchDelegate<void> {
  final WidgetRef ref;

  ProjectSearchDelegate(this.ref)
      : super(searchFieldLabel: 'Projekte durchsuchen…');

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = '',
            tooltip: 'Suche löschen',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => close(context, null),
        tooltip: 'Zurück',
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final projectsAsync = ref.watch(allProjectsProvider);
    final q = query.toLowerCase().trim();

    return projectsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (projects) {
        final filtered = q.isEmpty
            ? projects
            : projects.where((p) {
                return p.title.toLowerCase().contains(q) ||
                    p.genre.toLowerCase().contains(q) ||
                    p.tags.any((t) => t.toLowerCase().contains(q)) ||
                    (p.synopsis?.toLowerCase().contains(q) ?? false);
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                q.isEmpty
                    ? 'Suche nach Titel, Genre oder Tag'
                    : 'Keine Projekte für "$q"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final p = filtered[i];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: _HighlightText(text: p.title, query: q),
              subtitle: Text(
                '${p.genre} · ${(p.progressPercent * 100).round()}%',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: DeadlineBadge(project: p),
              onTap: () {
                close(context, null);
                context.push('/projects/${p.id}');
              },
            );
          },
        );
      },
    );
  }
}

/// Highlights matching query substring in text.
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text);

    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx == -1) return Text(text);

    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

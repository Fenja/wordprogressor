import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/projects/domain/project_model.dart';
import '../../../features/projects/providers/project_providers.dart';

part 'deadline_providers.g.dart';

@riverpod
Future<List<ProjectModel>> projectsWithDeadlines(
    ProjectsWithDeadlinesRef ref) async {
  final all = await ref.watch(allProjectsProvider.future);
  return all
      .where((p) =>
          p.deadline != null && p.status != ProjectStatus.submitted)
      .toList()
    ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
}

@riverpod
Future<List<ProjectModel>> overdueProjects(OverdueProjectsRef ref) async {
  final projects = await ref.watch(projectsWithDeadlinesProvider.future);
  return projects
      .where((p) => p.deadlineStatus == DeadlineStatus.overdue)
      .toList();
}

@riverpod
Future<int> overdueCount(OverdueCountRef ref) async {
  final overdue = await ref.watch(overdueProjectsProvider.future);
  return overdue.length;
}

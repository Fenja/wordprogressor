import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/project_repository.dart';
import '../domain/project_model.dart';

part 'project_providers.g.dart';

// ── All Projects ──────────────────────────────────────────────────────────

@riverpod
Stream<List<ProjectModel>> allProjects(AllProjectsRef ref) {
  return ref.watch(projectRepositoryProvider).watchAllProjects();
}

@riverpod
Stream<List<ProjectModel>> activeProjects(ActiveProjectsRef ref) {
  return ref.watch(projectRepositoryProvider).watchActiveProjects();
}

// ── Single Project ────────────────────────────────────────────────────────

@riverpod
Future<ProjectModel?> project(ProjectRef ref, String id) {
  return ref.watch(projectRepositoryProvider).getProject(id);
}

// ── Stats from projects ───────────────────────────────────────────────────

@riverpod
Future<ProjectStats> projectStats(ProjectStatsRef ref) async {
  final projects = await ref.watch(allProjectsProvider.future);

  final active = projects.where((p) =>
      p.status == ProjectStatus.active || p.status == ProjectStatus.draft).length;
  final completed =
      projects.where((p) => p.status == ProjectStatus.submitted).length;
  final totalWords = projects.fold<int>(0, (s, p) => s + p.wordCountCurrent);
  final overdue = projects.where((p) => p.deadlineStatus == DeadlineStatus.overdue).length;

  return ProjectStats(
    totalProjects: projects.length,
    activeProjects: active,
    completedProjects: completed,
    totalWords: totalWords,
    overdueDeadlines: overdue,
  );
}

class ProjectStats {
  final int totalProjects;
  final int activeProjects;
  final int completedProjects;
  final int totalWords;
  final int overdueDeadlines;

  const ProjectStats({
    required this.totalProjects,
    required this.activeProjects,
    required this.completedProjects,
    required this.totalWords,
    required this.overdueDeadlines,
  });
}

// ── Filter state ──────────────────────────────────────────────────────────

enum ProjectFilter { all, active, completed, paused }

final projectFilterProvider =
    StateProvider<ProjectFilter>((ref) => ProjectFilter.all);

final filteredProjectsProvider = Provider<AsyncValue<List<ProjectModel>>>((ref) {
  final filter = ref.watch(projectFilterProvider);
  final projects = ref.watch(allProjectsProvider);

  return projects.whenData((list) {
    switch (filter) {
      case ProjectFilter.all:
        return list;
      case ProjectFilter.active:
        return list
            .where((p) =>
                p.status == ProjectStatus.active ||
                p.status == ProjectStatus.draft)
            .toList();
      case ProjectFilter.completed:
        return list
            .where((p) => p.status == ProjectStatus.submitted)
            .toList();
      case ProjectFilter.paused:
        return list
            .where((p) => p.status == ProjectStatus.abandoned)
            .toList();
    }
  });
});

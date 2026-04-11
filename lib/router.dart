import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wordprogressor/features/achievements/presentation/achievements_screen.dart';

import '../features/deadlines/presentation/deadlines_screen.dart';
import '../features/milestones/presentation/milestones_screen.dart';
import '../features/projects/presentation/project_detail_screen.dart';
import '../features/projects/presentation/project_form_screen.dart';
import '../features/projects/presentation/project_list_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../shared/widgets/main_scaffold.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/projects',
    debugLogDiagnostics: false,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/projects',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProjectListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                const ProjectFormScreen(projectId: null),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    ProjectDetailScreen(projectId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => ProjectFormScreen(
                        projectId: state.pathParameters['id']),
                  ),
                  GoRoute(
                    path: 'milestones',
                    builder: (context, state) => MilestonesScreen(
                        projectId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/deadlines',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DeadlinesScreen(),
            ),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StatsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/achievements',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AchievementsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}
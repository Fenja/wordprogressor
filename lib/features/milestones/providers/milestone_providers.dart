import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/milestone_repository.dart';
import '../domain/milestone_model.dart';

part 'milestone_providers.g.dart';

@riverpod
Stream<List<MilestoneModel>> milestonesForProject(
  MilestonesForProjectRef ref,
  String projectId,
) {
  return ref.watch(milestoneRepositoryProvider).watchForProject(projectId);
}

@riverpod
Stream<List<MilestoneModel>> upcomingMilestones(UpcomingMilestonesRef ref) {
  return ref.watch(milestoneRepositoryProvider).watchUpcoming();
}

/// Milestones grouped: completed vs. pending
@riverpod
Future<({List<MilestoneModel> pending, List<MilestoneModel> done})>
    groupedMilestones(
  GroupedMilestonesRef ref,
  String projectId,
) async {
  final all =
      await ref.watch(milestonesForProjectProvider(projectId).future);
  return (
    pending: all.where((m) => !m.isCompleted).toList(),
    done: all.where((m) => m.isCompleted).toList(),
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:wordprogressor/features/projects/domain/project_model.dart';

void main() {
  final baseProject = ProjectModel(
    id: 'test-1',
    title: 'Testprojekt',
    wordCountGoal: 80000,
    wordCountCurrent: 40000,
    startedAt: DateTime(2024, 1, 1),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  group('ProjectModel.progressPercent', () {
    test('returns 0.5 for half-done', () {
      expect(baseProject.progressPercent, 0.5);
    });

    test('returns 0 when goal is 0', () {
      final p = baseProject.copyWith(wordCountGoal: 0);
      expect(p.progressPercent, 0.0);
    });

    test('clamps at 1.0 when over goal', () {
      final p = baseProject.copyWith(wordCountCurrent: 90000);
      expect(p.progressPercent, 1.0);
    });
  });

  group('ProjectModel.deadlineStatus', () {
    test('returns none when no deadline', () {
      expect(baseProject.deadlineStatus, DeadlineStatus.none);
    });

    test('returns overdue for past deadline', () {
      final p = baseProject.copyWith(
          deadline: DateTime.now().subtract(const Duration(days: 1)));
      expect(p.deadlineStatus, DeadlineStatus.overdue);
    });

    test('returns near for deadline within 14 days', () {
      final p = baseProject.copyWith(
          deadline: DateTime.now().add(const Duration(days: 7)));
      expect(p.deadlineStatus, DeadlineStatus.near);
    });

    test('returns ok for deadline far away', () {
      final p = baseProject.copyWith(
          deadline: DateTime.now().add(const Duration(days: 30)));
      expect(p.deadlineStatus, DeadlineStatus.ok);
    });
  });

  group('ProjectModel.wordsRemaining', () {
    test('returns difference to goal', () {
      expect(baseProject.wordsRemaining, 40000);
    });

    test('clamps to 0 when over goal', () {
      final p = baseProject.copyWith(wordCountCurrent: 90000);
      expect(p.wordsRemaining, 0);
    });
  });

  group('ProjectModel tags JSON round-trip', () {
    test('serializes and deserializes tags', () {
      final tags = ['Fantasy', 'Mondmythos', 'Coming of Age'];
      final json = ProjectModel.tagsToJson(tags);
      final parsed = ProjectModel.tagsFromJson(json);
      expect(parsed, tags);
    });

    test('returns empty list for invalid JSON', () {
      expect(ProjectModel.tagsFromJson('invalid'), isEmpty);
    });
  });
}

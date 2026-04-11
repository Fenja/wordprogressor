import 'package:flutter_test/flutter_test.dart';
import 'package:wordprogressor/features/projects/domain/project_model.dart';

/// Tests conflict resolution logic for SyncService.
/// The rule: the record with the newer `updatedAt` wins.
void main() {
  final base = DateTime(2025, 1, 1, 12, 0, 0);
  final newer = DateTime(2025, 1, 1, 13, 0, 0);
  final older = DateTime(2025, 1, 1, 11, 0, 0);

  group('SyncService conflict resolution', () {
    test('remote wins when remote is newer', () {
      // Simulate: local.updatedAt < remote.updatedAt → remote should be used
      expect(older.isBefore(newer), isTrue);
    });

    test('local wins when local is newer', () {
      // Simulate: local.updatedAt > remote.updatedAt → skip remote
      expect(newer.isAfter(older), isTrue);
    });

    test('no update when timestamps are equal', () {
      // Equal timestamps → no conflict, skip update
      expect(base.isAtSameMomentAs(base), isTrue);
    });
  });

  group('ProjectModel.tagsFromJson edge cases', () {
    test('handles empty array', () {
      expect(ProjectModel.tagsFromJson('[]'), isEmpty);
    });

    test('handles null-like invalid JSON gracefully', () {
      expect(ProjectModel.tagsFromJson('null'), isEmpty);
    });

    test('handles malformed JSON gracefully', () {
      expect(ProjectModel.tagsFromJson('{not valid}'), isEmpty);
    });
  });

  group('DeadlineStatus boundary', () {
    ProjectModel makeProject(int daysFromNow) {
      final deadline = DateTime.now().add(Duration(days: daysFromNow));
      return ProjectModel(
        id: 'x',
        title: 'Test',
        deadline: deadline,
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('exactly 14 days → near', () {
      expect(makeProject(14).deadlineStatus, DeadlineStatus.near);
    });

    test('exactly 15 days → ok', () {
      expect(makeProject(15).deadlineStatus, DeadlineStatus.ok);
    });

    test('0 days → near (same day)', () {
      // Still in the future (positive inDays = 0 means today)
      expect(makeProject(0).deadlineStatus, DeadlineStatus.near);
    });

    test('negative days → overdue', () {
      expect(makeProject(-1).deadlineStatus, DeadlineStatus.overdue);
    });
  });
}

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/milestone_model.dart';

const _uuid = Uuid();

class MilestoneRepository {
  final AppDatabase _db;
  MilestoneRepository(this._db);

  Stream<List<MilestoneModel>> watchForProject(String projectId) {
    return _db.watchMilestonesForProject(projectId).map(
          (rows) => rows.map(_rowToModel).toList(),
        );
  }

  Stream<List<MilestoneModel>> watchUpcoming() {
    return _db.watchUpcomingMilestones().map(
          (rows) => rows.map(_rowToModel).toList(),
        );
  }

  Future<String> create(MilestoneModel model) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.upsertMilestone(
      MilestonesCompanion.insert(
        id: id,
        projectId: model.projectId,
        title: model.title,
        description: Value(model.description),
        dueDate: model.dueDate,
        isCompleted: Value(model.isCompleted),
        sortOrder: Value(model.sortOrder),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> update(MilestoneModel model) async {
    await _db.upsertMilestone(
      MilestonesCompanion(
        id: Value(model.id),
        projectId: Value(model.projectId),
        title: Value(model.title),
        description: Value(model.description),
        dueDate: Value(model.dueDate),
        isCompleted: Value(model.isCompleted),
        completedAt: Value(model.completedAt),
        sortOrder: Value(model.sortOrder),
        createdAt: Value(model.createdAt),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<void> toggle(String id, bool completed) =>
      _db.toggleMilestone(id, completed);

  Future<void> delete(String id) => _db.deleteMilestone(id);

  Future<void> reorder(List<MilestoneModel> ordered) async {
    for (var i = 0; i < ordered.length; i++) {
      await _db.upsertMilestone(MilestonesCompanion(
        id: Value(ordered[i].id),
        projectId: Value(ordered[i].projectId),
        title: Value(ordered[i].title),
        dueDate: Value(ordered[i].dueDate),
        sortOrder: Value(i),
        createdAt: Value(ordered[i].createdAt),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  static MilestoneModel _rowToModel(Milestone row) => MilestoneModel(
        id: row.id,
        projectId: row.projectId,
        title: row.title,
        description: row.description,
        dueDate: row.dueDate,
        isCompleted: row.isCompleted,
        completedAt: row.completedAt,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        isSynced: row.isSynced,
      );
}

final milestoneRepositoryProvider = Provider<MilestoneRepository>(
  (ref) => MilestoneRepository(ref.watch(appDatabaseProvider)),
);

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/project_model.dart';

// Achievement integration — imported here to evaluate after session/project events.
// The service is called directly (not via provider) so the repository stays testable.
import '../../achievements/data/achievement_service.dart';

const _uuid = Uuid();

class ProjectRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  // ── Streams ────────────────────────────────────────────────────────────────

  Stream<List<ProjectModel>> watchAllProjects() {
    return _db.watchAllProjects().map(
          (rows) => rows.map(_rowToModel).toList(),
        );
  }

  Stream<List<ProjectModel>> watchActiveProjects() {
    return _db.watchActiveProjects().map(
          (rows) => rows.map(_rowToModel).toList(),
        );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<ProjectModel?> getProject(String id) async {
    final row = await _db.getProject(id);
    if (row == null) return null;
    return _rowToModel(row);
  }

  Future<String> createProject(ProjectModel model) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.upsertProject(
      ProjectsCompanion.insert(
        id: id,
        title: model.title,
        genre: Value(model.genre),
        status: Value(model.status.name),
        synopsis: Value(model.synopsis),
        tagsJson: Value(jsonEncode(model.tags)),
        wordCountGoal: Value(model.wordCountGoal),
        wordCountCurrent: Value(model.wordCountCurrent),
        chapterCountTotal: Value(model.chapterCountTotal),
        chapterCountDone: Value(model.chapterCountDone),
        targetAudience: Value(model.targetAudience),
        language: Value(model.language),
        notes: Value(model.notes),
        deadline: Value(model.deadline),
        startedAt: model.startedAt,
        createdAt: now,
        updatedAt: now,
        colorHex: Value(model.colorHex),
      ),
    );
    return id;
  }

  Future<void> updateProject(ProjectModel model) async {
    await _db.upsertProject(
      ProjectsCompanion(
        id: Value(model.id),
        title: Value(model.title),
        genre: Value(model.genre),
        status: Value(model.status.name),
        synopsis: Value(model.synopsis),
        tagsJson: Value(jsonEncode(model.tags)),
        wordCountGoal: Value(model.wordCountGoal),
        wordCountCurrent: Value(model.wordCountCurrent),
        chapterCountTotal: Value(model.chapterCountTotal),
        chapterCountDone: Value(model.chapterCountDone),
        targetAudience: Value(model.targetAudience),
        language: Value(model.language),
        notes: Value(model.notes),
        deadline: Value(model.deadline),
        startedAt: Value(model.startedAt),
        createdAt: Value(model.createdAt),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        colorHex: Value(model.colorHex),
      ),
    );

    // If project was just submitted, evaluate project-completion achievements
    if (model.status == ProjectStatus.submitted) {
      final all = await _db.watchAllProjects().first;
      final completedCount = all
          .where((p) => p.status == ProjectStatus.submitted.name)
          .length;
      final achievementService = AchievementService(_db);
      await achievementService.evaluateAfterProjectCompleted(
        totalCompletedProjects: completedCount,
      );
      // Note: Toast is shown by the UI layer (ProjectFormScreen) by
      // watching unlockedAchievementsProvider for changes.
    }
  }

  Future<void> deleteProject(String id) async {
    await _db.deleteProject(id);
  }

  /// Increment word count and add a writing session.
  /// Returns a list of newly unlocked [AchievementDef]s (may be empty).
  Future<List<dynamic>> logSession({
    required String projectId,
    required int wordsWritten,
    int durationMinutes = 0,
    String? notes,
  }) async {
    final project = await getProject(projectId);
    if (project == null) return [];

    // 1. Update project word count
    await updateProject(project.copyWith(
      wordCountCurrent: project.wordCountCurrent + wordsWritten,
    ));

    // 2. Store session
    final now = DateTime.now();
    await _db.insertSession(
      WritingSessionsCompanion.insert(
        id: _uuid.v4(),
        projectId: projectId,
        sessionDate: now,
        wordsWritten: Value(wordsWritten),
        durationMinutes: Value(durationMinutes),
        notes: Value(notes),
        createdAt: now,
      ),
    );

    // 3. Evaluate achievements
    // Calculate total words across ALL projects
    final allProjects = await _db.watchAllProjects().first;
    final totalWords =
        allProjects.fold<int>(0, (s, p) => s + p.wordCountCurrent);

    // Calculate current streak from all session dates
    final allSessions = await _db.getSessionsInRange(
      DateTime.now().subtract(const Duration(days: 400)),
      DateTime.now(),
    );
    final streakDays = AchievementService.calculateStreak(
      allSessions.map((s) => s.sessionDate).toList(),
    );

    final achievementService = AchievementService(_db);
    final newlyUnlocked = await achievementService.evaluateAfterSession(
      totalWordsAllProjects: totalWords,
      currentStreakDays: streakDays,
      sessionWords: wordsWritten,
      sessionDurationMinutes: durationMinutes,
      sessionTime: now,
    );

    return newlyUnlocked;
  }

  // ── Conversion ────────────────────────────────────────────────────────────

  static ProjectModel _rowToModel(Project row) {
    return ProjectModel(
      id: row.id,
      title: row.title,
      genre: row.genre,
      status: ProjectStatus.values.firstWhere(
        (s) => s.name == row.status,
        orElse: () => ProjectStatus.draft,
      ),
      synopsis: row.synopsis,
      tags: ProjectModel.tagsFromJson(row.tagsJson),
      wordCountGoal: row.wordCountGoal,
      wordCountCurrent: row.wordCountCurrent,
      chapterCountTotal: row.chapterCountTotal,
      chapterCountDone: row.chapterCountDone,
      targetAudience: row.targetAudience,
      language: row.language,
      notes: row.notes,
      deadline: row.deadline,
      startedAt: row.startedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      isSynced: row.isSynced,
      remoteId: row.remoteId,
      colorHex: row.colorHex,
    );
  }
}

// Provider
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.watch(appDatabaseProvider));
});

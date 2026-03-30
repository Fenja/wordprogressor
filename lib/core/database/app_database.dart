import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ─── Tables ────────────────────────────────────────────────────────────────

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get genre => text().withDefault(const Constant('Unbekannt'))();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  // draft | active | revision | submitted | abandoned
  TextColumn get synopsis => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  IntColumn get wordCountGoal => integer().withDefault(const Constant(0))();
  IntColumn get wordCountCurrent => integer().withDefault(const Constant(0))();
  IntColumn get chapterCountTotal => integer().withDefault(const Constant(0))();
  IntColumn get chapterCountDone => integer().withDefault(const Constant(0))();
  TextColumn get targetAudience => text().nullable()();
  TextColumn get language => text().withDefault(const Constant('Deutsch'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();
  TextColumn get remoteId => text().nullable()();
  // Color accent for card (hex string)
  TextColumn get colorHex => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Milestones extends Table {
  TextColumn get id => text()();
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class WritingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get sessionDate => dateTime()();
  IntColumn get wordsWritten => integer().withDefault(const Constant(0))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

// ─── Database ──────────────────────────────────────────────────────────────

@DriftDatabase(tables: [Projects, Milestones, WritingSessions, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Future migrations go here
      },
    );
  }

  // ── Projects ──────────────────────────────────────────────────────────────

  Stream<List<Project>> watchAllProjects() {
    return (select(projects)
      ..orderBy([
            (p) => OrderingTerm(
          expression: p.updatedAt,
          mode: OrderingMode.desc,
        ),
      ]))
        .watch();
  }

  Stream<List<Project>> watchActiveProjects() {
    return (select(projects)
      ..where((p) =>
          p.status.isIn(['active', 'draft', 'revision']))
      ..orderBy([(p) => OrderingTerm(expression: p.updatedAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<Project?> getProject(String id) {
    return (select(projects)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertProject(ProjectsCompanion project) {
    return into(projects).insertOnConflictUpdate(project);
  }

  Future<void> deleteProject(String id) {
    return (delete(projects)..where((p) => p.id.equals(id))).go();
  }

  Future<List<Project>> getUnsyncedProjects() {
    return (select(projects)
      ..where((p) => p.isSynced.equals(false)))
        .get();
  }

  Future<void> markProjectSynced(String id) {
    return (update(projects)..where((p) => p.id.equals(id)))
        .write(const ProjectsCompanion(isSynced: Value(true)));
  }

  // ── Milestones ────────────────────────────────────────────────────────────

  Stream<List<Milestone>> watchMilestonesForProject(String projectId) {
    return (select(milestones)
      ..where((m) => m.projectId.equals(projectId))
      ..orderBy([(m) => OrderingTerm(expression: m.sortOrder)]))
        .watch();
  }

  Stream<List<Milestone>> watchUpcomingMilestones() {
    final now = DateTime.now();
    return (select(milestones)
      ..where((m) =>
      m.isCompleted.equals(false) &
      m.dueDate.isBiggerOrEqualValue(now))
      ..orderBy([(m) => OrderingTerm(expression: m.dueDate)]))
        .watch();
  }

  Future<void> upsertMilestone(MilestonesCompanion milestone) {
    return into(milestones).insertOnConflictUpdate(milestone);
  }

  Future<void> toggleMilestone(String id, bool completed) {
    return (update(milestones)..where((m) => m.id.equals(id))).write(
      MilestonesCompanion(
        isCompleted: Value(completed),
        completedAt: Value(completed ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
      ),
    );
  }

  Future<void> deleteMilestone(String id) {
    return (delete(milestones)..where((m) => m.id.equals(id))).go();
  }

  // ── Writing Sessions ──────────────────────────────────────────────────────

  Stream<List<WritingSession>> watchSessionsForProject(String projectId) {
    return (select(writingSessions)
      ..where((s) => s.projectId.equals(projectId))
      ..orderBy([(s) =>
          OrderingTerm(expression: s.sessionDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<WritingSession>> getSessionsInRange(
      DateTime from, DateTime to) {
    return (select(writingSessions)
      ..where((s) =>
          s.sessionDate.isBetweenValues(from, to)))
        .get();
  }

  Future<void> insertSession(WritingSessionsCompanion session) {
    return into(writingSessions).insert(session);
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)
      ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) {
    return into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion(key: Value(key), value: Value(value)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wordprogressor.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Override in main.dart');
});
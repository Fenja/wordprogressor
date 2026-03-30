import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/projects/data/project_repository.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart' show Value;

/// SyncService handles bidirectional sync between local SQLite (Drift)
/// and Cloud Firestore.
///
/// Strategy: Offline-First with last-write-wins conflict resolution
/// using `updatedAt` timestamps.
class SyncService {
  final AppDatabase _db;
  final ProjectRepository _projectRepo;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SyncService({
    required AppDatabase db,
    required ProjectRepository projectRepo,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = db,
        _projectRepo = projectRepo,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _firestore.collection('users').doc(_uid).collection('projects');

  CollectionReference<Map<String, dynamic>> get _milestonesRef =>
      _firestore.collection('users').doc(_uid).collection('milestones');

  // ── Full Sync ─────────────────────────────────────────────────────────────

  /// Push all unsynced local changes to Firestore, then pull remote changes.
  Future<SyncResult> sync() async {
    if (_uid == null) {
      return const SyncResult(success: false, message: 'Nicht angemeldet');
    }

    try {
      await _pushProjects();
      await _pullProjects();
      return const SyncResult(success: true, message: 'Synchronisation abgeschlossen');
    } catch (e) {
      return SyncResult(success: false, message: 'Sync-Fehler: $e');
    }
  }

  // ── Push (local → remote) ─────────────────────────────────────────────────

  Future<void> _pushProjects() async {
    final unsynced = await _db.getUnsyncedProjects();
    final batch = _firestore.batch();

    for (final row in unsynced) {
      final docRef = _projectsRef.doc(row.id);
      batch.set(docRef, _projectToFirestore(row), SetOptions(merge: true));
    }

    await batch.commit();

    for (final row in unsynced) {
      await _db.markProjectSynced(row.id);
    }
  }

  // ── Pull (remote → local) ─────────────────────────────────────────────────

  Future<void> _pullProjects() async {
    final snapshot = await _projectsRef.get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final remoteUpdatedAt =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      final local = await _db.getProject(doc.id);

      // Skip if local is newer
      if (local != null && local.updatedAt.isAfter(remoteUpdatedAt)) continue;

      await _db.upsertProject(_firestoreToCompanion(doc.id, data));
    }
  }

  // ── Serialization ─────────────────────────────────────────────────────────

  static Map<String, dynamic> _projectToFirestore(Project row) {
    return {
      'title': row.title,
      'genre': row.genre,
      'status': row.status,
      'synopsis': row.synopsis,
      'tagsJson': row.tagsJson,
      'wordCountGoal': row.wordCountGoal,
      'wordCountCurrent': row.wordCountCurrent,
      'chapterCountTotal': row.chapterCountTotal,
      'chapterCountDone': row.chapterCountDone,
      'targetAudience': row.targetAudience,
      'language': row.language,
      'notes': row.notes,
      'deadline':
      row.deadline != null ? Timestamp.fromDate(row.deadline!) : null,
      'startedAt': Timestamp.fromDate(row.startedAt),
      'createdAt': Timestamp.fromDate(row.createdAt),
      'updatedAt': Timestamp.fromDate(row.updatedAt),
      'colorHex': row.colorHex,
    };
  }

  static ProjectsCompanion _firestoreToCompanion(
      String id, Map<String, dynamic> data) {
    DateTime? parseTs(String key) {
      final ts = data[key];
      if (ts is Timestamp) return ts.toDate();
      return null;
    }

    return ProjectsCompanion(
      id: Value(id),
      title: Value(data['title'] as String? ?? ''),
      genre: Value(data['genre'] as String? ?? 'Unbekannt'),
      status: Value(data['status'] as String? ?? 'draft'),
      synopsis: Value(data['synopsis'] as String?),
      tagsJson: Value(data['tagsJson'] as String? ?? '[]'),
      wordCountGoal: Value(data['wordCountGoal'] as int? ?? 0),
      wordCountCurrent: Value(data['wordCountCurrent'] as int? ?? 0),
      chapterCountTotal: Value(data['chapterCountTotal'] as int? ?? 0),
      chapterCountDone: Value(data['chapterCountDone'] as int? ?? 0),
      targetAudience: Value(data['targetAudience'] as String?),
      language: Value(data['language'] as String? ?? 'Deutsch'),
      notes: Value(data['notes'] as String?),
      deadline: Value(parseTs('deadline')),
      startedAt: Value(parseTs('startedAt') ?? DateTime.now()),
      createdAt: Value(parseTs('createdAt') ?? DateTime.now()),
      updatedAt: Value(parseTs('updatedAt') ?? DateTime.now()),
      isSynced: const Value(true),
      remoteId: Value(id),
      colorHex: Value(data['colorHex'] as String?),
    );
  }
}

class SyncResult {
  final bool success;
  final String message;
  const SyncResult({required this.success, required this.message});
}

// Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    db: ref.watch(appDatabaseProvider),
    projectRepo: ref.watch(projectRepositoryProvider),
  );
});
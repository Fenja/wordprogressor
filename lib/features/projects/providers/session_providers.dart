import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/database/app_database.dart';

part 'session_providers.g.dart';

/// Sessions for a single project as a stream.
@riverpod
Stream<List<WritingSession>> sessionsForProject(
  SessionsForProjectRef ref,
  String projectId,
) {
  return ref
      .watch(appDatabaseProvider)
      .watchSessionsForProject(projectId);
}

/// Aggregated stats for a project: total words, total time, session count.
@riverpod
Future<SessionStats> sessionStats(
  SessionStatsRef ref,
  String projectId,
) async {
  final sessions =
      await ref.watch(sessionsForProjectProvider(projectId).future);

  final totalWords =
      sessions.fold<int>(0, (s, e) => s + e.wordsWritten);
  final totalMinutes =
      sessions.fold<int>(0, (s, e) => s + e.durationMinutes);
  final avgWords = sessions.isEmpty
      ? 0
      : (totalWords / sessions.length).round();

  return SessionStats(
    sessionCount: sessions.length,
    totalWords: totalWords,
    totalMinutes: totalMinutes,
    avgWordsPerSession: avgWords,
  );
}

/// Words written per day for the last N days (for bar chart).
@riverpod
Future<List<DailyWords>> recentDailyWords(
  RecentDailyWordsRef ref,
  String projectId, {
  int days = 7,
}) async {
  final now = DateTime.now();
  final from = now.subtract(Duration(days: days - 1));
  final start = DateTime(from.year, from.month, from.day);

  final sessions = await ref
      .watch(appDatabaseProvider)
      .getSessionsInRange(start, now);

  // Group by date
  final Map<String, int> byDay = {};
  for (final s in sessions) {
    if (s.projectId != projectId) continue;
    final key =
        '${s.sessionDate.year}-${s.sessionDate.month.toString().padLeft(2, '0')}-${s.sessionDate.day.toString().padLeft(2, '0')}';
    byDay[key] = (byDay[key] ?? 0) + s.wordsWritten;
  }

  // Build ordered list for the last N days
  return List.generate(days, (i) {
    final d = start.add(Duration(days: i));
    final key =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return DailyWords(date: d, words: byDay[key] ?? 0);
  });
}

class SessionStats {
  final int sessionCount;
  final int totalWords;
  final int totalMinutes;
  final int avgWordsPerSession;

  const SessionStats({
    required this.sessionCount,
    required this.totalWords,
    required this.totalMinutes,
    required this.avgWordsPerSession,
  });
}

class DailyWords {
  final DateTime date;
  final int words;
  const DailyWords({required this.date, required this.words});
}

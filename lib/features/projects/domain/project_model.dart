import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

enum ProjectStatus {
  draft,
  active,
  revision,
  submitted,
  published,
  abandoned;

  String get label {
    switch (this) {
      case ProjectStatus.draft:
        return 'Entwurf';
      case ProjectStatus.active:
        return 'Aktiv';
      case ProjectStatus.revision:
        return 'Überarbeitung';
      case ProjectStatus.submitted:
        return 'Eingereicht';
      case ProjectStatus.published:
        return 'Veröffentlicht';
      case ProjectStatus.abandoned:
        return 'Pausiert';
    }
  }
}

@freezed
class ProjectModel with _$ProjectModel {
  const ProjectModel._();

  const factory ProjectModel({
    required String id,
    required String title,
    @Default('Unbekannt') String genre,
    @Default(ProjectStatus.draft) ProjectStatus status,
    String? synopsis,
    @Default([]) List<String> tags,
    @Default(0) int wordCountGoal,
    @Default(0) int wordCountCurrent,
    @Default(0) int chapterCountTotal,
    @Default(0) int chapterCountDone,
    String? targetAudience,
    @Default('Deutsch') String language,
    String? notes,
    DateTime? deadline,
    required DateTime startedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isSynced,
    String? remoteId,
    String? colorHex,
  }) = _ProjectModel;

  factory ProjectModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectModelFromJson(json);

  // Computed
  double get progressPercent {
    if (wordCountGoal <= 0) return 0;
    return (wordCountCurrent / wordCountGoal).clamp(0.0, 1.0);
  }

  double get chapterProgress {
    if (chapterCountTotal <= 0) return 0;
    return (chapterCountDone / chapterCountTotal).clamp(0.0, 1.0);
  }

  DeadlineStatus get deadlineStatus {
    if (deadline == null) return DeadlineStatus.none;
    final now = DateTime.now();
    final diff = deadline!.difference(now).inDays;
    if (diff < 0) return DeadlineStatus.overdue;
    if (diff <= 14) return DeadlineStatus.near;
    return DeadlineStatus.ok;
  }

  int? get daysUntilDeadline {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  int get wordsRemaining => (wordCountGoal - wordCountCurrent).clamp(0, wordCountGoal);

  /// Returns tags from JSON string stored in DB
  static List<String> tagsFromJson(String json) {
    try {
      final list = jsonDecode(json) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static String tagsToJson(List<String> tags) => jsonEncode(tags);
}

enum DeadlineStatus { none, ok, near, overdue }

// Known genres for dropdown
const kGenres = [
  'Roman',
  'Novelle',
  'Kurzgeschichte',
  'Lyrik / Gedichtband',
  'Drama / Theaterstück',
  'Drehbuch',
  'Essay',
  'Sachbuch',
  'Sonstiges',
];

const kGenreIcons = <String, String>{
  'Roman': '📖',
  'Novelle': '📕',
  'Kurzgeschichte': '📄',
  'Lyrik / Gedichtband': '✍️',
  'Drama / Theaterstück': '🎭',
  'Drehbuch': '🎬',
  'Essay': '💡',
  'Sachbuch': '🔬',
  'Sonstiges': '📝',
};

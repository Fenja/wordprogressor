import 'package:freezed_annotation/freezed_annotation.dart';

part 'milestone_model.freezed.dart';
part 'milestone_model.g.dart';

@freezed
class MilestoneModel with _$MilestoneModel {
  const MilestoneModel._();

  const factory MilestoneModel({
    required String id,
    required String projectId,
    required String title,
    String? description,
    required DateTime dueDate,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
    @Default(0) int sortOrder,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isSynced,
  }) = _MilestoneModel;

  factory MilestoneModel.fromJson(Map<String, dynamic> json) =>
      _$MilestoneModelFromJson(json);

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());
}

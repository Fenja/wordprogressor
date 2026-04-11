import 'package:flutter/material.dart';
import '../../domain/project_model.dart';
import '../../../../../core/theme/app_theme.dart';

class DeadlineBadge extends StatelessWidget {
  final ProjectModel project;
  final bool large;

  const DeadlineBadge({super.key, required this.project, this.large = false});

  @override
  Widget build(BuildContext context) {
    final status = project.deadlineStatus;
    if (status == DeadlineStatus.none) return const SizedBox.shrink();

    final days = project.daysUntilDeadline;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bg, fg, label) = _resolve(status, days, isDark);

    return Semantics(
      label: _semanticLabel(status, days),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7,
          vertical: large ? 5 : 3,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(status), size: large ? 13 : 11, color: fg),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: large ? 12 : 10,
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, String) _resolve(
      DeadlineStatus status, int? days, bool isDark) {
    switch (status) {
      case DeadlineStatus.ok:
        return (
          isDark ? AppColors.deadlineOkBgDark : AppColors.deadlineOkBg,
          isDark ? AppColors.deadlineOkDark : AppColors.deadlineOk,
          '${days} Tage',
        );
      case DeadlineStatus.near:
        return (
          isDark ? AppColors.deadlineNearBgDark : AppColors.deadlineNearBg,
          isDark ? AppColors.deadlineNearDark : AppColors.deadlineNear,
          '${days} Tage',
        );
      case DeadlineStatus.overdue:
        return (
          isDark ? AppColors.deadlineOverBgDark : AppColors.deadlineOverBg,
          isDark ? AppColors.deadlineOverDark : AppColors.deadlineOver,
          'Überfällig',
        );
      case DeadlineStatus.none:
        return (Colors.transparent, Colors.transparent, '');
    }
  }

  IconData _icon(DeadlineStatus status) {
    switch (status) {
      case DeadlineStatus.ok:
        return Icons.check_circle_outline_rounded;
      case DeadlineStatus.near:
        return Icons.schedule_rounded;
      case DeadlineStatus.overdue:
        return Icons.warning_amber_rounded;
      case DeadlineStatus.none:
        return Icons.circle_outlined;
    }
  }

  String _semanticLabel(DeadlineStatus status, int? days) {
    switch (status) {
      case DeadlineStatus.ok:
        return 'Deadline in $days Tagen';
      case DeadlineStatus.near:
        return 'Deadline bald: noch $days Tage';
      case DeadlineStatus.overdue:
        return 'Deadline überschritten';
      case DeadlineStatus.none:
        return '';
    }
  }
}

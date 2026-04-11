import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/achievement_model.dart';

class AchievementCard extends StatelessWidget {
  final AchievementDef def;
  final DateTime? unlockedAt; // null = locked
  final bool compact;

  const AchievementCard({
    super.key,
    required this.def,
    required this.unlockedAt,
    this.compact = false,
  });

  bool get _unlocked => unlockedAt != null;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final theme = Theme.of(context);

    final tierColor = def.tier.borderColor(brightness);
    final tierBg =
        _unlocked ? def.tier.bgColor(brightness) : Colors.transparent;

    return Semantics(
      label:
          '${def.title}: ${def.description}. ${_unlocked ? 'Freigeschaltet am ${DateFormat('dd. MMMM yyyy', 'de').format(unlockedAt!)}' : 'Noch nicht freigeschaltet'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _unlocked
              ? tierBg
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _unlocked
                ? tierColor
                : theme.colorScheme.outlineVariant.withOpacity(0.3),
            width: _unlocked ? 1.5 : 0.5,
          ),
        ),
        child: compact ? _CompactContent(def: def, unlocked: _unlocked, unlockedAt: unlockedAt, tierColor: tierColor)
                       : _FullContent(def: def, unlocked: _unlocked, unlockedAt: unlockedAt, tierColor: tierColor),
      ),
    );
  }
}

class _FullContent extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;
  final DateTime? unlockedAt;
  final Color tierColor;

  const _FullContent({
    required this.def,
    required this.unlocked,
    required this.unlockedAt,
    required this.tierColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Emoji with lock overlay when locked
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    def.emoji,
                    style: TextStyle(
                      fontSize: 28,
                      color: unlocked ? null : Colors.transparent,
                    ),
                  ),
                  if (!unlocked)
                    const Positioned.fill(
                      child: Center(
                        child: Text('🔒', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              // Tier badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  def.tier.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            def.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: unlocked
                  ? null
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            def.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: unlocked
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
          ),
          if (unlocked && unlockedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              DateFormat('dd. MMM yyyy', 'de').format(unlockedAt!),
              style: TextStyle(
                fontSize: 10,
                color: tierColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactContent extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;
  final DateTime? unlockedAt;
  final Color tierColor;

  const _CompactContent({
    required this.def,
    required this.unlocked,
    required this.unlockedAt,
    required this.tierColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Text(
            unlocked ? def.emoji : '🔒',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: unlocked
                          ? null
                          : theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.5),
                    )),
                Text(def.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withOpacity(unlocked ? 1 : 0.4),
                    )),
              ],
            ),
          ),
          if (unlocked)
            Icon(Icons.check_circle_rounded, color: tierColor, size: 18),
        ],
      ),
    );
  }
}

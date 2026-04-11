import 'package:flutter/material.dart';
import '../../domain/achievement_model.dart';

/// Shows a temporary banner at the top of the screen when an achievement
/// is unlocked. Call via AchievementToast.show(context, def).
class AchievementToast {
  static OverlayEntry? _current;

  static void show(BuildContext context, AchievementDef def) {
    _current?.remove();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AchievementBanner(
        def: def,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }
}

class _AchievementBanner extends StatefulWidget {
  final AchievementDef def;
  final VoidCallback onDismiss;

  const _AchievementBanner({required this.def, required this.onDismiss});

  @override
  State<_AchievementBanner> createState() => _AchievementBannerState();
}

class _AchievementBannerState extends State<_AchievementBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    _ctrl.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () async {
      if (mounted) {
        await _ctrl.reverse();
        if (mounted) widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tierColor = widget.def.tier.borderColor(brightness);
    final tierBg = widget.def.tier.bgColor(brightness);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () async {
                await _ctrl.reverse();
                widget.onDismiss();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: tierBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tierColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Text(widget.def.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Achievement freigeschaltet!',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tierColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.def.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.def.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.close_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

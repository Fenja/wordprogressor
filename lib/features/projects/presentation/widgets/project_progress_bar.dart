import 'package:flutter/material.dart';

class ProjectProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double height;
  final String semanticLabel;

  const ProjectProgressBar({
    super.key,
    required this.value,
    this.height = 5,
    this.semanticLabel = '',
  });

  Color _colorForValue(BuildContext context, double v) {
    if (v >= 0.9) return Colors.green.shade600;
    if (v >= 0.5) return Theme.of(context).colorScheme.primary;
    if (v >= 0.25) return Colors.orange.shade600;
    return Colors.orange.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForValue(context, value);

    return Semantics(
      label: semanticLabel.isEmpty
          ? 'Fortschritt: ${(value * 100).round()} Prozent'
          : semanticLabel,
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
          value: value,
          minHeight: height,
          backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
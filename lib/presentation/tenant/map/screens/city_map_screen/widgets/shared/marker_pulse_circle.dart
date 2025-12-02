import 'package:flutter/material.dart';

class MarkerPulseCircle extends StatelessWidget {
  const MarkerPulseCircle({
    super.key,
    required this.progress,
    required this.color,
    required this.maxSize,
  });

  final double progress;
  final Color color;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOut.transform(progress);
    final size = (eased.clamp(0.1, 1.0)) * maxSize;
    final opacity = (1 - eased).clamp(0.0, 1.0);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16 * opacity),
      ),
    );
  }
}

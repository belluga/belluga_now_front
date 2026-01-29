import 'package:flutter/material.dart';

class MarkerFallbackIcon extends StatelessWidget {
  const MarkerFallbackIcon({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note,
        color: color,
        size: 28,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AvatarFallback extends StatelessWidget {
  const AvatarFallback({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note_outlined,
        color: color,
      ),
    );
  }
}

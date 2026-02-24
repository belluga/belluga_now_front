import 'package:flutter/material.dart';

class FavoriteBadgeGlyph extends StatelessWidget {
  const FavoriteBadgeGlyph({
    super.key,
    required this.codePoint,
    required this.fontFamily,
    required this.size,
    required this.color,
  });

  final int codePoint;
  final String? fontFamily;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (codePoint <= 0) return const SizedBox.shrink();
    return Text(
      String.fromCharCode(codePoint),
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        color: color,
        height: 1,
      ),
    );
  }
}

import 'package:flutter/material.dart';

enum ResolvedProfileTypeVisualKind {
  icon,
  image,
}

class ResolvedProfileTypeVisual {
  const ResolvedProfileTypeVisual.icon({
    required this.iconData,
    this.backgroundColor,
    this.iconColor,
  })  : kind = ResolvedProfileTypeVisualKind.icon,
        imageUrl = null;

  const ResolvedProfileTypeVisual.image({
    required this.imageUrl,
  })  : kind = ResolvedProfileTypeVisualKind.image,
        iconData = null,
        backgroundColor = null,
        iconColor = null;

  final ResolvedProfileTypeVisualKind kind;
  final IconData? iconData;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? imageUrl;

  bool get isIcon => kind == ResolvedProfileTypeVisualKind.icon;
  bool get isImage => kind == ResolvedProfileTypeVisualKind.image;
}

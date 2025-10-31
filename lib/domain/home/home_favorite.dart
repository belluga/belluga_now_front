import 'package:flutter/material.dart';

class HomeFavorite {
  const HomeFavorite({
    required this.title,
    this.imageUrl,
    this.assetPath,
    this.badgeIcon,
    this.isPrimary = false,
  });

  final String title;
  final String? imageUrl;
  final String? assetPath;
  final IconData? badgeIcon;
  final bool isPrimary;
}

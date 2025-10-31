import 'package:flutter/material.dart';

class FavoriteItemData {
  const FavoriteItemData({
    required this.title,
    required this.imageUrl,
    this.badgeIcon,
    this.isPrimary = false,
  });

  final String title;
  final String imageUrl;
  final IconData? badgeIcon;
  final bool isPrimary;
}

import 'package:flutter/material.dart';

class FavoriteItemData {
  const FavoriteItemData({
    required this.title,
    this.imageUrl,
    this.assetPath,
    this.badgeIcon,
    this.isPrimary = false,
  })  : assert(
          imageUrl != null || assetPath != null,
          'Provide either an imageUrl or an assetPath.',
        ),
        assert(
          imageUrl == null || assetPath == null,
          'Only one of imageUrl or assetPath can be provided.',
        );

  final String title;
  final String? imageUrl;
  final String? assetPath;
  final IconData? badgeIcon;
  final bool isPrimary;
}

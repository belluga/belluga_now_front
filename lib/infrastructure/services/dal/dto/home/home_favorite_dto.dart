import 'package:belluga_now/domain/home/home_favorite.dart';
import 'package:flutter/material.dart';

class HomeFavoriteDTO {
  const HomeFavoriteDTO({
    required this.title,
    this.imageUrl,
    this.assetPath,
    this.badgeIconCodePoint,
    this.badgeFontFamily,
    this.badgeFontPackage,
    this.isPrimary = false,
  });

  factory HomeFavoriteDTO.withBadgeIcon({
    required String title,
    String? imageUrl,
    String? assetPath,
    IconData? badgeIcon,
    bool isPrimary = false,
  }) {
    return HomeFavoriteDTO(
      title: title,
      imageUrl: imageUrl,
      assetPath: assetPath,
      badgeIconCodePoint: badgeIcon?.codePoint,
      badgeFontFamily: badgeIcon?.fontFamily,
      badgeFontPackage: badgeIcon?.fontPackage,
      isPrimary: isPrimary,
    );
  }

  final String title;
  final String? imageUrl;
  final String? assetPath;
  final int? badgeIconCodePoint;
  final String? badgeFontFamily;
  final String? badgeFontPackage;
  final bool isPrimary;

  HomeFavorite toDomain() {
    return HomeFavorite(
      title: title,
      imageUrl: imageUrl,
      assetPath: assetPath,
      badgeIcon: badgeIconCodePoint != null
          ? IconData(
              badgeIconCodePoint!,
              fontFamily: badgeFontFamily,
              fontPackage: badgeFontPackage,
            )
          : null,
      isPrimary: isPrimary,
    );
  }
}

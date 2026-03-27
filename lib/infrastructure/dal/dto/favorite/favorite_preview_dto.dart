import 'package:flutter/material.dart';
import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_family_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_package_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_icon_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_id_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_primary_flag_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class FavoritePreviewDTO {
  const FavoritePreviewDTO({
    required this.id,
    required this.title,
    this.slug,
    this.targetId,
    this.registryKey,
    this.targetType,
    this.favoritedAt,
    this.nextEventOccurrenceAt,
    this.lastEventOccurrenceAt,
    this.imageUrl,
    this.assetPath,
    this.badgeIconCodePoint,
    this.badgeFontFamily,
    this.badgeFontPackage,
    this.isPrimary = false,
  });

  factory FavoritePreviewDTO.withBadgeIcon({
    required String id,
    required String title,
    String? slug,
    String? imageUrl,
    String? assetPath,
    IconData? badgeIcon,
    bool isPrimary = false,
  }) {
    return FavoritePreviewDTO(
      id: id,
      title: title,
      slug: slug,
      targetId: id,
      imageUrl: imageUrl,
      assetPath: assetPath,
      badgeIconCodePoint: badgeIcon?.codePoint,
      badgeFontFamily: badgeIcon?.fontFamily,
      badgeFontPackage: badgeIcon?.fontPackage,
      isPrimary: isPrimary,
    );
  }

  factory FavoritePreviewDTO.fromJson(Map<String, dynamic> json) {
    final targetRaw = json['target'];
    final target = targetRaw is Map<String, dynamic>
        ? targetRaw
        : const <String, dynamic>{};
    final snapshotRaw = json['snapshot'];
    final snapshot = snapshotRaw is Map<String, dynamic>
        ? snapshotRaw
        : const <String, dynamic>{};
    final navigationRaw = json['navigation'];
    final navigation = navigationRaw is Map<String, dynamic>
        ? navigationRaw
        : const <String, dynamic>{};

    final targetId =
        (json['target_id'] ?? target['id'] ?? '').toString().trim();
    final title =
        (target['display_name'] ?? json['title'] ?? targetId).toString().trim();
    final slug =
        (navigation['target_slug'] ?? target['slug'])?.toString().trim();

    DateTime? parseDate(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value.trim());
      }
      return null;
    }

    return FavoritePreviewDTO(
      id: targetId.isNotEmpty
          ? targetId
          : (json['favorite_id'] ?? '').toString().trim(),
      title: title.isNotEmpty ? title : targetId,
      slug: (slug != null && slug.isNotEmpty) ? slug : null,
      targetId: targetId.isNotEmpty ? targetId : null,
      registryKey: (json['registry_key'] ?? '').toString().trim(),
      targetType: (json['target_type'] ?? '').toString().trim(),
      favoritedAt: parseDate(json['favorited_at']),
      nextEventOccurrenceAt: parseDate(snapshot['next_event_occurrence_at']),
      lastEventOccurrenceAt: parseDate(snapshot['last_event_occurrence_at']),
      imageUrl: target['avatar_url']?.toString(),
      assetPath: null,
      isPrimary: false,
    );
  }

  final String id;
  final String title;
  final String? slug;
  final String? targetId;
  final String? registryKey;
  final String? targetType;
  final DateTime? favoritedAt;
  final DateTime? nextEventOccurrenceAt;
  final DateTime? lastEventOccurrenceAt;
  final String? imageUrl;
  final String? assetPath;
  final int? badgeIconCodePoint;
  final String? badgeFontFamily;
  final String? badgeFontPackage;
  final bool isPrimary;

  Favorite toDomain() {
    final safeTitle = title.trim().isNotEmpty ? title : id;
    final titleValue = TitleValue()..parse(safeTitle);
    final idValue = FavoriteIdValue()..parse(id);
    final isPrimaryValue = FavoritePrimaryFlagValue()
      ..parse(isPrimary.toString());

    SlugValue? slugValue;
    if (slug != null && slug!.trim().isNotEmpty) {
      slugValue = SlugValue()..parse(slug);
    }

    ThumbUriValue? imageUriValue;
    if (imageUrl != null) {
      final parsed = Uri.tryParse(imageUrl!);
      if (parsed != null) {
        imageUriValue = ThumbUriValue(
          defaultValue: parsed,
          isRequired: true,
        )..parse(imageUrl);
      }
    }

    AssetPathValue? assetPathValue;
    if (assetPath != null && assetPath!.trim().isNotEmpty) {
      assetPathValue = AssetPathValue(
        defaultValue: assetPath!,
        isRequired: true,
      )..parse(assetPath);
    } else if (imageUriValue == null) {
      assetPathValue = AssetPathValue(
        defaultValue: 'assets/images/placeholder_avatar.png',
        isRequired: true,
      )..parse('assets/images/placeholder_avatar.png');
    }

    FavoriteBadge? badge;
    if (badgeIconCodePoint != null) {
      final iconValue = FavoriteBadgeIconValue()
        ..parse(badgeIconCodePoint!.toString());
      FavoriteBadgeFontFamilyValue? fontFamilyValue;
      if (badgeFontFamily != null && badgeFontFamily!.isNotEmpty) {
        fontFamilyValue = FavoriteBadgeFontFamilyValue()
          ..parse(badgeFontFamily);
      }
      FavoriteBadgeFontPackageValue? fontPackageValue;
      if (badgeFontPackage != null && badgeFontPackage!.isNotEmpty) {
        fontPackageValue = FavoriteBadgeFontPackageValue()
          ..parse(badgeFontPackage);
      }
      badge = FavoriteBadge(
        iconValue: iconValue,
        fontFamilyValue: fontFamilyValue,
        fontPackageValue: fontPackageValue,
      );
    }

    return Favorite(
      idValue: idValue,
      slugValue: slugValue,
      titleValue: titleValue,
      imageUriValue: imageUriValue,
      assetPathValue: assetPathValue,
      badge: badge,
      isPrimaryValue: isPrimaryValue,
    );
  }
}

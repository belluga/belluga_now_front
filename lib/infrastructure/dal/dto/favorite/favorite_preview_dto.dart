import 'package:flutter/material.dart';

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
}

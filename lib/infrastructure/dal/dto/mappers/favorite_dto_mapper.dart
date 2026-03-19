import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_icon_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_family_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_font_package_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';

mixin FavoriteDtoMapper {
  Favorite mapFavorite(FavoritePreviewDTO dto) {
    final safeTitle = dto.title.trim().isNotEmpty ? dto.title : dto.id;
    final title = TitleValue()..parse(safeTitle);

    ThumbUriValue? imageUri;
    if (dto.imageUrl != null) {
      final parsed = Uri.tryParse(dto.imageUrl!);
      if (parsed != null) {
        imageUri = ThumbUriValue(
          defaultValue: parsed,
          isRequired: true,
        )..parse(dto.imageUrl);
      }
    }

    AssetPathValue? assetPath;
    if (dto.assetPath != null && dto.assetPath!.trim().isNotEmpty) {
      assetPath = AssetPathValue(
        defaultValue: dto.assetPath!,
        isRequired: true,
      )..parse(dto.assetPath);
    } else if (imageUri == null) {
      // Snapshot payload may not include avatar_url; keep UI contract valid with a deterministic fallback.
      assetPath = AssetPathValue(
        defaultValue: 'assets/images/placeholder_avatar.png',
        isRequired: true,
      )..parse('assets/images/placeholder_avatar.png');
    }

    FavoriteBadge? badge;
    if (dto.badgeIconCodePoint != null) {
      final iconValue = FavoriteBadgeIconValue()
        ..parse(dto.badgeIconCodePoint!.toString());
      FavoriteBadgeFontFamilyValue? fontFamily;
      if (dto.badgeFontFamily != null && dto.badgeFontFamily!.isNotEmpty) {
        fontFamily = FavoriteBadgeFontFamilyValue()..parse(dto.badgeFontFamily);
      }
      FavoriteBadgeFontPackageValue? fontPackage;
      if (dto.badgeFontPackage != null && dto.badgeFontPackage!.isNotEmpty) {
        fontPackage = FavoriteBadgeFontPackageValue()
          ..parse(dto.badgeFontPackage);
      }
      badge = FavoriteBadge(
        iconValue: iconValue,
        fontFamilyValue: fontFamily,
        fontPackageValue: fontPackage,
      );
    }

    return Favorite(
      id: dto.id,
      slug: dto.slug,
      titleValue: title,
      imageUriValue: imageUri,
      assetPathValue: assetPath,
      badge: badge,
      isPrimary: dto.isPrimary,
    );
  }
}

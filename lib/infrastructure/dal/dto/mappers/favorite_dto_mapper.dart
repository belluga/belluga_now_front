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
    final title = TitleValue()..parse(dto.title);

    ThumbUriValue? imageUri;
    if (dto.imageUrl != null) {
      imageUri = ThumbUriValue(
        defaultValue: Uri.parse(dto.imageUrl!),
        isRequired: true,
      )..parse(dto.imageUrl);
    }

    AssetPathValue? assetPath;
    if (dto.assetPath != null) {
      assetPath = AssetPathValue(
        defaultValue: dto.assetPath!,
        isRequired: true,
      )..parse(dto.assetPath);
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
      titleValue: title,
      imageUriValue: imageUri,
      assetPathValue: assetPath,
      badge: badge,
      isPrimary: dto.isPrimary,
    );
  }
}

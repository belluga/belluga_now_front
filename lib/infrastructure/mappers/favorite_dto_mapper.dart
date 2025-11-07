import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/home/home_favorite_dto.dart';

mixin FavoriteDtoMapper {
  Favorite mapFavorite(HomeFavoriteDTO dto) {
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

    final badge = dto.badgeIconCodePoint != null
        ? FavoriteBadgeValue(
            codePoint: dto.badgeIconCodePoint!,
            fontFamily: dto.badgeFontFamily,
            fontPackage: dto.badgeFontPackage,
          )
        : null;

    return Favorite(
      id: dto.id ?? Favorite.slugify(dto.title),
      titleValue: title,
      imageUriValue: imageUri,
      assetPathValue: assetPath,
      badgeValue: badge,
      isPrimary: dto.isPrimary,
    );
  }
}

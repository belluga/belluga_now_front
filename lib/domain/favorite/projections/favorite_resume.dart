import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:flutter/material.dart';

class FavoriteResume {
  FavoriteResume({
    required this.titleValue,
    this.imageUriValue,
    this.assetPathValue,
    this.badgeValue,
    this.isPrimary = false,
  })  : assert(
          imageUriValue != null || assetPathValue != null,
          'Provide either an image or an asset path.',
        ),
        assert(
          imageUriValue == null || assetPathValue == null,
          'Only one of image or asset path can be provided.',
        );

  final TitleValue titleValue;
  final ThumbUriValue? imageUriValue;
  final AssetPathValue? assetPathValue;
  final FavoriteBadgeValue? badgeValue;
  final bool isPrimary;

  String get title => titleValue.value;
  Uri? get imageUri => imageUriValue?.value;
  String? get assetPath => assetPathValue?.value;

  IconData? get badgeIcon => badgeValue == null
      ? null
      : IconData(
          badgeValue!.codePoint,
          fontFamily: badgeValue!.fontFamily,
          fontPackage: badgeValue!.fontPackage,
        );

  factory FavoriteResume.fromFavorite(Favorite favorite) {
    return FavoriteResume(
      titleValue: favorite.titleValue,
      imageUriValue: favorite.imageUriValue,
      assetPathValue: favorite.assetPathValue,
      badgeValue: favorite.badgeValue,
      isPrimary: favorite.isPrimary,
    );
  }
}

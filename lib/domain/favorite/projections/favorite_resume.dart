import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_primary_flag_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:flutter/material.dart';

class FavoriteResume {
  FavoriteResume({
    required this.titleValue,
    this.slugValue,
    this.imageUriValue,
    this.assetPathValue,
    this.badge,
    FavoritePrimaryFlagValue? isPrimaryValue,
    this.iconImageUriValue,
    this.primaryColor,
  })  : assert(
          imageUriValue != null || assetPathValue != null,
          'Provide either an image or an asset path.',
        ),
        assert(
          imageUriValue == null || assetPathValue == null,
          'Only one of image or asset path can be provided.',
        ),
        isPrimaryValue =
            isPrimaryValue ?? (FavoritePrimaryFlagValue()..parse('false'));

  final TitleValue titleValue;
  final SlugValue? slugValue;
  final ThumbUriValue? imageUriValue;
  final AssetPathValue? assetPathValue;
  final FavoriteBadge? badge;
  final FavoritePrimaryFlagValue isPrimaryValue;
  final ThumbUriValue? iconImageUriValue;
  final Color? primaryColor;

  String? get slug => slugValue?.value;
  bool get isPrimary => isPrimaryValue.value;
  String? get iconImageUrl => iconImageUriValue?.value.toString();
  String get title => titleValue.value;
  Uri? get imageUri => imageUriValue?.value;
  String? get assetPath => assetPathValue?.value;

  factory FavoriteResume.fromFavorite(Favorite favorite) {
    return FavoriteResume(
      titleValue: favorite.titleValue,
      slugValue: favorite.slugValue,
      imageUriValue: favorite.imageUriValue,
      assetPathValue: favorite.assetPathValue,
      badge: favorite.badge,
      isPrimaryValue: favorite.isPrimaryValue,
    );
  }
}

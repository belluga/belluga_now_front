import 'package:belluga_now/domain/favorite/favorite.dart';
import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class FavoriteResume {
  FavoriteResume({
    required this.titleValue,
    this.imageUriValue,
    this.assetPathValue,
    this.badge,
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
  final FavoriteBadge? badge;
  final bool isPrimary;

  String get title => titleValue.value;
  Uri? get imageUri => imageUriValue?.value;
  String? get assetPath => assetPathValue?.value;

  factory FavoriteResume.fromFavorite(Favorite favorite) {
    return FavoriteResume(
      titleValue: favorite.titleValue,
      imageUriValue: favorite.imageUriValue,
      assetPathValue: favorite.assetPathValue,
      badge: favorite.badge,
      isPrimary: favorite.isPrimary,
    );
  }
}

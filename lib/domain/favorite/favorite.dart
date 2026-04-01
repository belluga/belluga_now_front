import 'package:belluga_now/domain/favorite/favorite_badge.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_id_value.dart';
import 'package:belluga_now/domain/favorite/value_objects/favorite_primary_flag_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class Favorite {
  Favorite({
    required this.idValue,
    required this.titleValue,
    this.slugValue,
    this.imageUriValue,
    this.assetPathValue,
    this.badge,
    FavoritePrimaryFlagValue? isPrimaryValue,
  })  : assert(
          imageUriValue != null || assetPathValue != null,
          'Provide either an image or an asset path.',
        ),
        assert(
          imageUriValue == null || assetPathValue == null,
          'Only one of image or asset path can be provided.',
        ),
        isPrimaryValue =
            isPrimaryValue ?? (FavoritePrimaryFlagValue()..parse('false')),
        assert(
          idValue.value.trim().isNotEmpty,
          'Favorite id cannot be empty',
        );

  final FavoriteIdValue idValue;
  final SlugValue? slugValue;
  final TitleValue titleValue;
  final ThumbUriValue? imageUriValue;
  final AssetPathValue? assetPathValue;
  final FavoriteBadge? badge;
  final FavoritePrimaryFlagValue isPrimaryValue;

  String get id => idValue.value;
  String? get slug => slugValue?.value;
  bool get isPrimary => isPrimaryValue.value;
  String get title => titleValue.value;
  Uri? get imageUri => imageUriValue?.value;
  String? get assetPath => assetPathValue?.value;
}

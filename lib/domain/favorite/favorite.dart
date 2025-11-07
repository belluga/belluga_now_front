import 'package:belluga_now/domain/favorite/value_objects/favorite_badge_value.dart';
import 'package:belluga_now/domain/value_objects/asset_path_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class Favorite {
  Favorite({
    required this.id,
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
        ),
        assert(id.trim().isNotEmpty, 'Favorite id cannot be empty');

  final String id;
  final TitleValue titleValue;
  final ThumbUriValue? imageUriValue;
  final AssetPathValue? assetPathValue;
  final FavoriteBadgeValue? badgeValue;
  final bool isPrimary;

  String get title => titleValue.value;
  Uri? get imageUri => imageUriValue?.value;
  String? get assetPath => assetPathValue?.value;

  static String slugify(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/static_assets/value_objects/public_static_asset_fields.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class PublicStaticAssetModel {
  PublicStaticAssetModel({
    required this.idValue,
    required this.profileTypeValue,
    required this.displayNameValue,
    required this.slugValue,
    this.coverValue,
    this.bioValue,
    this.contentValue,
    this.locationLatitudeValue,
    this.locationLongitudeValue,
  });

  final PublicStaticAssetIdValue idValue;
  final PublicStaticAssetTypeValue profileTypeValue;
  final PublicStaticAssetNameValue displayNameValue;
  final SlugValue slugValue;
  final ThumbUriValue? coverValue;
  final PublicStaticAssetDescriptionValue? bioValue;
  final PublicStaticAssetDescriptionValue? contentValue;
  final LatitudeValue? locationLatitudeValue;
  final LongitudeValue? locationLongitudeValue;

  String get id => idValue.value;
  String get profileType => profileTypeValue.value;
  String get displayName => displayNameValue.value;
  String get slug => slugValue.value;
  Uri? get coverUri => coverValue?.value;
  String? get coverUrl => coverUri?.toString();
  String? get bio => bioValue?.value;
  String? get content => contentValue?.value;
  double? get locationLat => locationLatitudeValue?.value;
  double? get locationLng => locationLongitudeValue?.value;

  String? get resolvedDescription {
    final normalizedContent = content?.trim();
    if (normalizedContent != null && normalizedContent.isNotEmpty) {
      return normalizedContent;
    }
    final normalizedBio = bio?.trim();
    if (normalizedBio != null && normalizedBio.isNotEmpty) {
      return normalizedBio;
    }
    return null;
  }

  String get typeLabel {
    final normalized = profileType
        .trim()
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.split(' ').map((part) {
      if (part.isEmpty) {
        return part;
      }
      return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }

  bool get hasLocation => locationLat != null && locationLng != null;
}

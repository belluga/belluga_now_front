import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/domain/static_assets/value_objects/public_static_asset_fields.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';

class PublicStaticAssetDto {
  const PublicStaticAssetDto({
    required this.id,
    required this.profileType,
    required this.displayName,
    required this.slug,
    this.coverUrl,
    this.bio,
    this.content,
    this.locationLat,
    this.locationLng,
  });

  final String id;
  final String profileType;
  final String displayName;
  final String slug;
  final String? coverUrl;
  final String? bio;
  final String? content;
  final double? locationLat;
  final double? locationLng;

  factory PublicStaticAssetDto.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    double? lat;
    double? lng;
    if (location is Map<String, dynamic>) {
      lat = _parseDouble(location['lat']);
      lng = _parseDouble(location['lng']);
    }
    return PublicStaticAssetDto(
      id: json['id']?.toString() ?? '',
      profileType: json['profile_type']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      coverUrl: json['cover_url']?.toString(),
      bio: json['bio']?.toString(),
      content: json['content']?.toString(),
      locationLat: lat,
      locationLng: lng,
    );
  }

  PublicStaticAssetModel toDomain() {
    final normalizedCoverUrl = _normalizeOptional(coverUrl);
    final normalizedBio = _normalizeOptional(bio);
    final normalizedContent = _normalizeOptional(content);
    final slugValue = SlugValue()..parse(slug);
    final coverValue = normalizedCoverUrl == null
        ? null
        : ThumbUriValue(defaultValue: Uri.parse(normalizedCoverUrl));
    final latitudeValue = locationLat == null
        ? null
        : (LatitudeValue(isRequired: false)..parse(locationLat.toString()));
    final longitudeValue = locationLng == null
        ? null
        : (LongitudeValue(isRequired: false)..parse(locationLng.toString()));
    return PublicStaticAssetModel(
      idValue: PublicStaticAssetIdValue(defaultValue: id),
      profileTypeValue: PublicStaticAssetTypeValue(
        defaultValue: profileType,
        isRequired: false,
      ),
      displayNameValue: PublicStaticAssetNameValue(defaultValue: displayName),
      slugValue: slugValue,
      coverValue: coverValue,
      bioValue: normalizedBio == null
          ? null
          : PublicStaticAssetDescriptionValue(
              defaultValue: normalizedBio,
              isRequired: false,
            ),
      contentValue: normalizedContent == null
          ? null
          : PublicStaticAssetDescriptionValue(
              defaultValue: normalizedContent,
              isRequired: false,
            ),
      locationLatitudeValue: latitudeValue,
      locationLongitudeValue: longitudeValue,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static String? _normalizeOptional(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

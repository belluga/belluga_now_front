import 'package:belluga_now/domain/map/value_objects/city_poi_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';

class CityPoiLinkedProfile {
  const CityPoiLinkedProfile({
    required this.idValue,
    required this.displayNameValue,
    this.avatarImageUriValue,
  });

  final PoiReferenceIdValue idValue;
  final CityPoiNameValue displayNameValue;
  final PoiFilterImageUriValue? avatarImageUriValue;

  String get id => idValue.value;
  String get displayName => displayNameValue.value;
  String? get avatarImageUri {
    final raw = avatarImageUriValue?.value.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }
}

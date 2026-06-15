import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';

class AccountProfileReferencePointResolver {
  const AccountProfileReferencePointResolver._();

  static const String entityNamespace = 'account_profile';

  static bool canUseAccountProfile(
    AccountProfileModel accountProfile, {
    required ProfileTypeCapabilities? capabilities,
    CityCoordinate? fallbackCoordinate,
  }) {
    if (capabilities?.isReferenceLocationEnabled != true) {
      return false;
    }
    if (accountProfile.id.trim().isEmpty ||
        accountProfile.profileType.trim().isEmpty) {
      return false;
    }
    return _coordinateFor(accountProfile, fallbackCoordinate) != null;
  }

  static FixedLocationReference? buildFromAccountProfile(
    AccountProfileModel accountProfile, {
    CityCoordinate? fallbackCoordinate,
  }) {
    final coordinate = _coordinateFor(accountProfile, fallbackCoordinate);
    if (coordinate == null) {
      return null;
    }
    return FixedLocationReference(
      sourceKind: FixedLocationReferenceSourceKind.entityReference,
      coordinate: coordinate,
      labelValue: _optionalText(accountProfile.name),
      entityNamespaceValue: _optionalText(entityNamespace),
      entityTypeValue: _optionalText(accountProfile.profileType),
      entityIdValue: _optionalText(accountProfile.id),
      entitySlugValue: _optionalText(accountProfile.slug),
    );
  }

  static bool matchesAccountProfile(
    FixedLocationReference? fixedReference,
    AccountProfileModel accountProfile,
  ) {
    return matchesEntity(
      fixedReference,
      entityType: accountProfile.profileType,
      entityId: accountProfile.id,
      entitySlug: accountProfile.slug,
    );
  }

  static bool matchesEntity(
    FixedLocationReference? fixedReference, {
    required String entityType,
    required String entityId,
    String? entitySlug,
  }) {
    if (fixedReference == null ||
        !fixedReference.isActive ||
        fixedReference.sourceKind !=
            FixedLocationReferenceSourceKind.entityReference) {
      return false;
    }
    if (fixedReference.entityNamespace != entityNamespace) {
      return false;
    }

    final normalizedType = entityType.trim().toLowerCase();
    final referenceType = fixedReference.entityType?.trim().toLowerCase();
    if (normalizedType.isNotEmpty &&
        referenceType != null &&
        referenceType.isNotEmpty &&
        referenceType != normalizedType) {
      return false;
    }

    final normalizedId = entityId.trim();
    final idMatches = normalizedId.isNotEmpty &&
        fixedReference.entityId?.trim() == normalizedId;
    final normalizedSlug = entitySlug?.trim();
    final slugMatches = normalizedSlug != null &&
        normalizedSlug.isNotEmpty &&
        fixedReference.entitySlug?.trim() == normalizedSlug;
    return idMatches || slugMatches;
  }

  static CityCoordinate? _coordinateFor(
    AccountProfileModel accountProfile,
    CityCoordinate? fallbackCoordinate,
  ) {
    final latitude = accountProfile.locationLat;
    final longitude = accountProfile.locationLng;
    if (latitude != null && longitude != null) {
      return CityCoordinate(
        latitudeValue: LatitudeValue()..parse(latitude.toString()),
        longitudeValue: LongitudeValue()..parse(longitude.toString()),
      );
    }
    return fallbackCoordinate;
  }

  static ProximityPreferenceOptionalTextValue? _optionalText(String raw) {
    final value = ProximityPreferenceOptionalTextValue.fromRaw(raw);
    return value.nullableValue == null ? null : value;
  }
}

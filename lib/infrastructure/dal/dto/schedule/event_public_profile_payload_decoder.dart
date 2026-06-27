import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_order_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/support/public_media_url_normalizer.dart';

final class EventPublicProfilePayloadDecoder {
  EventPublicProfilePayloadDecoder._();

  static List<EventLinkedAccountProfile> resolveLinkedAccountProfiles({
    required Object? linkedProfilesRaw,
  }) {
    final orderedIds = <String>[];
    final mergedProfiles = <String, Map<String, dynamic>>{};

    void addProfile(Map<String, dynamic> profile) {
      final id = _asString(profile['id'])?.trim() ?? '';
      if (id.isEmpty) {
        return;
      }

      final displayName = _asString(profile['display_name'])?.trim() ??
          _asString(profile['name'])?.trim() ??
          '';
      if (displayName.isEmpty) {
        return;
      }

      final existing = mergedProfiles[id];
      if (existing == null) {
        orderedIds.add(id);
        mergedProfiles[id] = Map<String, dynamic>.from(profile);
        return;
      }

      existing['display_name'] = _preferNonEmptyString(
        existing['display_name'],
        profile['display_name'] ?? profile['name'],
      );
      existing['name'] = _preferNonEmptyString(
        existing['name'],
        profile['name'],
      );
      existing['profile_type'] = _preferNonEmptyString(
        existing['profile_type'],
        profile['profile_type'],
      );
      existing['party_type'] = _preferNonEmptyString(
        existing['party_type'],
        profile['party_type'],
      );
      existing['slug'] = _preferNonEmptyString(
        existing['slug'],
        _extractProfileSlug(profile),
      );
      existing['can_open_public_detail'] = _preferTrueBool(
        existing['can_open_public_detail'],
        profile['can_open_public_detail'],
      );
      existing['public_detail_path'] = _preferNonEmptyString(
        existing['public_detail_path'],
        profile['public_detail_path'],
      );
      existing['avatar_url'] = _preferNonEmptyString(
        existing['avatar_url'],
        profile['avatar_url'] ?? profile['logo_url'],
      );
      existing['logo_url'] = _preferNonEmptyString(
        existing['logo_url'],
        profile['logo_url'],
      );
      existing['cover_url'] = _preferNonEmptyString(
        existing['cover_url'],
        profile['cover_url'] ?? profile['hero_image_url'],
      );
      existing['hero_image_url'] = _preferNonEmptyString(
        existing['hero_image_url'],
        profile['hero_image_url'],
      );
      existing['location'] = _preferNonEmptyMap(
        existing['location'],
        profile['location'],
      );
      existing['location_address'] = _preferNonEmptyString(
        existing['location_address'],
        profile['location_address'] ?? profile['address'],
      );
      existing['latitude'] = existing['latitude'] ?? profile['latitude'];
      existing['longitude'] = existing['longitude'] ?? profile['longitude'];
      existing['taxonomy_terms'] = _mergeTaxonomyTerms(
        existing['taxonomy_terms'],
        profile['taxonomy_terms'],
      );
    }

    if (linkedProfilesRaw is List) {
      for (final entry in linkedProfilesRaw) {
        addProfile(_asMap(entry));
      }
    }

    return List<EventLinkedAccountProfile>.unmodifiable(
      orderedIds
          .map((id) => _toLinkedAccountProfile(mergedProfiles[id]!))
          .whereType<EventLinkedAccountProfile>(),
    );
  }

  static List<EventProfileGroup> resolveProfileGroups(
    Object? raw, {
    List<EventLinkedAccountProfile> linkedAccountProfiles = const [],
  }) {
    if (raw is! List) {
      return const [];
    }

    final profilesById = <String, EventLinkedAccountProfile>{
      for (final profile in linkedAccountProfiles)
        if (profile.id.trim().isNotEmpty) profile.id.trim(): profile,
    };
    final groups = <EventProfileGroup>[];
    for (var index = 0; index < raw.length; index++) {
      final group = _asMap(raw[index]);
      final id = _asNullableString(group['id'] ?? group['key'])?.trim() ?? '';
      final label = _asNullableString(group['label'])?.trim() ?? '';
      if (id.isEmpty || label.isEmpty) {
        continue;
      }

      final profiles = resolveLinkedAccountProfiles(
        linkedProfilesRaw: group['profiles'],
      );
      final accountProfileIds = _resolveAccountProfileIds(
        group['account_profile_ids'] ?? group['profile_ids'],
      );
      final snapshotProfilesById = <String, EventLinkedAccountProfile>{
        for (final profile in profiles)
          if (profile.id.trim().isNotEmpty) profile.id.trim(): profile,
      };
      final authoritativeIds = accountProfileIds.isNotEmpty
          ? accountProfileIds
          : profiles
              .map((profile) => profile.id.trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false);
      final resolvedProfiles = authoritativeIds
          .map(
            (id) => _materializeGroupedProfile(
              aggregate: profilesById[id.trim()],
              snapshot: snapshotProfilesById[id.trim()],
            ),
          )
          .whereType<EventLinkedAccountProfile>()
          .toList(growable: false);
      if (resolvedProfiles.isEmpty && accountProfileIds.isEmpty) {
        continue;
      }

      groups.add(
        EventProfileGroup(
          idValue: EventLinkedAccountProfileTextValue(id),
          labelValue: EventLinkedAccountProfileTextValue(label),
          orderValue: EventProfileGroupOrderValue(
            _asInt(group['order'] ?? index),
          ),
          profiles: resolvedProfiles,
          accountProfileIdValues: (accountProfileIds.isEmpty
                  ? resolvedProfiles
                      .map((profile) => profile.id)
                      .toList(growable: false)
                  : accountProfileIds)
              .map(EventLinkedAccountProfileTextValue.new)
              .toList(growable: false),
        ),
      );
    }

    groups.sort((left, right) => left.order.compareTo(right.order));
    return List<EventProfileGroup>.unmodifiable(groups);
  }

  static List<String> _resolveAccountProfileIds(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return List<String>.unmodifiable(
      raw
          .map(_asString)
          .whereType<String>()
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty),
    );
  }

  static EventLinkedAccountProfile? _toLinkedAccountProfile(
    Map<String, dynamic> profile,
  ) {
    final id = _asString(profile['id'])?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }

    final displayName = _asString(profile['display_name'])?.trim() ??
        _asString(profile['name'])?.trim() ??
        '';
    if (displayName.isEmpty) {
      return null;
    }

    final taxonomyTermsRaw = profile['taxonomy_terms'];
    final taxonomyTerms = EventLinkedAccountProfileTaxonomyTerms();
    if (taxonomyTermsRaw is List) {
      for (final entry in taxonomyTermsRaw) {
        final term = _asMap(entry);
        final type = _asString(term['type'])?.trim() ?? '';
        final value = _asString(term['value'])?.trim() ?? '';
        if (type.isEmpty || value.isEmpty) {
          continue;
        }
        taxonomyTerms.addTerm(
          typeValue: AccountProfileTagValue(type),
          valueValue: AccountProfileTagValue(value),
          nameValue: AccountProfileTagValue(
            _asString(term['name'])?.trim() ??
                _asString(term['label'])?.trim() ??
                value,
          ),
          taxonomyNameValue: AccountProfileTagValue(
            _asString(term['taxonomy_name'])?.trim() ?? '',
          ),
          labelValue: AccountProfileTagValue(
            _asString(term['label'])?.trim() ?? '',
          ),
        );
      }
    }

    final profileType =
        _asString(profile['profile_type'])?.trim().isNotEmpty == true
            ? _asString(profile['profile_type'])!.trim()
            : (_asString(profile['party_type'])?.trim() ?? '');
    final locationCoordinates = _resolveProfileCoordinates(profile);

    return EventLinkedAccountProfile(
      idValue: EventLinkedAccountProfileTextValue(id),
      displayNameValue: EventLinkedAccountProfileTextValue(displayName),
      profileTypeValue: AccountProfileTypeValue(profileType),
      slugValue: _optionalLinkedAccountProfileSlugValue(profile: profile),
      avatarUrlValue: _thumbUriValueOrNull(
        _asNullableString(profile['avatar_url'] ?? profile['logo_url']),
      ),
      coverUrlValue: _thumbUriValueOrNull(
        _asNullableString(profile['cover_url'] ?? profile['hero_image_url']),
      ),
      partyTypeValue:
          _textValueOrNull(_asNullableString(profile['party_type'])),
      locationAddressValue: _textValueOrNull(
        _resolveProfileLocationAddress(profile),
      ),
      locationLatitudeValue: _latitudeValueOrNull(
        locationCoordinates.latitude,
      ),
      locationLongitudeValue: _longitudeValueOrNull(
        locationCoordinates.longitude,
      ),
      canOpenPublicDetailValue: _booleanValue(
        _resolveCanOpenPublicDetail(profile),
      ),
      publicDetailPathValue: _textValueOrNull(
        _resolvePublicDetailPath(profile),
      ),
      taxonomyTerms: taxonomyTerms,
    );
  }

  static EventLinkedAccountProfile _mergeLinkedAccountProfileWithAggregate(
    EventLinkedAccountProfile primary,
    EventLinkedAccountProfile? aggregate,
  ) {
    if (aggregate == null) {
      return primary;
    }

    return EventLinkedAccountProfile(
      idValue: primary.idValue,
      displayNameValue: primary.displayNameValue,
      profileTypeValue: primary.profileTypeValue,
      slugValue: primary.slugValue ?? aggregate.slugValue,
      avatarUrlValue: primary.avatarUrlValue ?? aggregate.avatarUrlValue,
      coverUrlValue: primary.coverUrlValue ?? aggregate.coverUrlValue,
      partyTypeValue: primary.partyTypeValue ?? aggregate.partyTypeValue,
      locationAddressValue:
          primary.locationAddressValue ?? aggregate.locationAddressValue,
      locationLatitudeValue:
          primary.locationLatitudeValue ?? aggregate.locationLatitudeValue,
      locationLongitudeValue:
          primary.locationLongitudeValue ?? aggregate.locationLongitudeValue,
      canOpenPublicDetailValue: primary.canOpenPublicDetail
          ? primary.canOpenPublicDetailValue
          : aggregate.canOpenPublicDetailValue,
      publicDetailPathValue:
          primary.publicDetailPathValue ?? aggregate.publicDetailPathValue,
      taxonomyTerms: _mergeDomainTaxonomyTerms(
        primary.taxonomyTerms,
        aggregate.taxonomyTerms,
      ),
    );
  }

  static EventLinkedAccountProfile? _materializeGroupedProfile({
    EventLinkedAccountProfile? aggregate,
    EventLinkedAccountProfile? snapshot,
  }) {
    if (aggregate != null && snapshot != null) {
      return _mergeLinkedAccountProfileWithAggregate(aggregate, snapshot);
    }
    return aggregate ?? snapshot;
  }

  static EventLinkedAccountProfileTaxonomyTerms _mergeDomainTaxonomyTerms(
    EventLinkedAccountProfileTaxonomyTerms primary,
    EventLinkedAccountProfileTaxonomyTerms aggregate,
  ) {
    if (primary.isEmpty) {
      return aggregate;
    }
    if (aggregate.isEmpty) {
      return primary;
    }

    final merged = EventLinkedAccountProfileTaxonomyTerms();
    final seen = <String>{};

    void ingest(EventLinkedAccountProfileTaxonomyTerms source) {
      for (final term in source) {
        final key = '${term.typeValue.value}:${term.valueValue.value}';
        if (!seen.add(key)) {
          continue;
        }
        merged.addTerm(
          typeValue: term.typeValue,
          valueValue: term.valueValue,
          nameValue: term.nameValue,
          taxonomyNameValue: term.taxonomyNameValue,
          labelValue: term.compatibilityLabelValue,
        );
      }
    }

    ingest(primary);
    ingest(aggregate);
    return merged;
  }

  static dynamic _preferNonEmptyString(dynamic current, dynamic candidate) {
    final currentValue = _asString(current)?.trim() ?? '';
    if (currentValue.isNotEmpty) {
      return current;
    }
    final candidateValue = _asString(candidate)?.trim() ?? '';
    return candidateValue.isNotEmpty ? candidate : current;
  }

  static dynamic _extractProfileSlug(Map<String, dynamic> profile) {
    return profile['slug'] ??
        profile['account_profile_slug'] ??
        profile['profile_slug'];
  }

  static dynamic _preferTrueBool(dynamic current, dynamic candidate) {
    if (_asBool(current)) {
      return true;
    }
    return _asBool(candidate) ? true : current;
  }

  static ({double? latitude, double? longitude}) _resolveProfileCoordinates(
    Map<String, dynamic> profile,
  ) {
    final directLatitude = _asDouble(profile['latitude'] ?? profile['lat']);
    final directLongitude = _asDouble(profile['longitude'] ?? profile['lng']);
    if (directLatitude != null && directLongitude != null) {
      return (latitude: directLatitude, longitude: directLongitude);
    }

    final location = _asMap(profile['location']);
    final locationLatitude = _asDouble(location['latitude'] ?? location['lat']);
    final locationLongitude =
        _asDouble(location['longitude'] ?? location['lng']);
    if (locationLatitude != null && locationLongitude != null) {
      return (latitude: locationLatitude, longitude: locationLongitude);
    }

    for (final geoSource in [location, _asMap(location['geo'])]) {
      final coordinates = geoSource['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        final lng = _asDouble(coordinates[0]);
        final lat = _asDouble(coordinates[1]);
        if (lat != null && lng != null) {
          return (latitude: lat, longitude: lng);
        }
      }
    }

    return (latitude: directLatitude, longitude: directLongitude);
  }

  static String? _resolveProfileLocationAddress(Map<String, dynamic> profile) {
    final location = _asMap(profile['location']);
    return _asNullableString(
      profile['location_address'] ??
          profile['address'] ??
          location['address'] ??
          location['address_line'] ??
          location['display_name'] ??
          location['label'],
    );
  }

  static SlugValue? _optionalLinkedAccountProfileSlugValue({
    required Map<String, dynamic> profile,
  }) {
    final slug = _asNullableString(_extractProfileSlug(profile))?.trim() ?? '';
    if (slug.isEmpty) {
      return null;
    }
    return SlugValue()..parse(slug);
  }

  static bool _resolveCanOpenPublicDetail(Map<String, dynamic> profile) {
    if (!_asBool(profile['can_open_public_detail'])) {
      return false;
    }

    final publicDetailPath = _resolvePublicDetailPath(profile);
    return publicDetailPath != null && publicDetailPath.isNotEmpty;
  }

  static String? _resolvePublicDetailPath(Map<String, dynamic> profile) {
    final path = _asNullableString(profile['public_detail_path'])?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }
    return path;
  }

  static EventLinkedAccountProfileTextValue? _textValueOrNull(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return EventLinkedAccountProfileTextValue(normalized);
  }

  static DomainBooleanValue _booleanValue(bool raw) {
    return DomainBooleanValue(defaultValue: false, isRequired: false)
      ..parse(raw.toString());
  }

  static LatitudeValue? _latitudeValueOrNull(double? value) {
    if (value == null) {
      return null;
    }
    return LatitudeValue()..parse(value.toString());
  }

  static LongitudeValue? _longitudeValueOrNull(double? value) {
    if (value == null) {
      return null;
    }
    return LongitudeValue()..parse(value.toString());
  }

  static ThumbUriValue? _thumbUriValueOrNull(String? rawUrl) {
    final normalized = normalizeTenantPublicMediaUrl(rawUrl);
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(normalized);
    if (parsed == null) {
      return null;
    }
    return ThumbUriValue(defaultValue: parsed, isRequired: true)
      ..parse(normalized);
  }

  static List<Map<String, dynamic>> _mergeTaxonomyTerms(
    dynamic currentRaw,
    dynamic candidateRaw,
  ) {
    final merged = <String, Map<String, dynamic>>{};

    void ingest(dynamic raw) {
      if (raw is! List) {
        return;
      }
      for (final entry in raw) {
        final term = _asMap(entry);
        final type = _asString(term['type'])?.trim() ?? '';
        final value = _asString(term['value'])?.trim() ?? '';
        if (type.isEmpty || value.isEmpty) {
          continue;
        }
        final key = '$type::$value';
        final existing = merged[key];
        if (existing == null) {
          merged[key] = Map<String, dynamic>.from(term);
          continue;
        }
        existing['name'] =
            _preferNonEmptyString(existing['name'], term['name']);
        existing['label'] =
            _preferNonEmptyString(existing['label'], term['label']);
        existing['taxonomy_name'] = _preferNonEmptyString(
          existing['taxonomy_name'],
          term['taxonomy_name'],
        );
      }
    }

    ingest(currentRaw);
    ingest(candidateRaw);

    return merged.values.toList(growable: false);
  }

  static dynamic _preferNonEmptyMap(dynamic current, dynamic candidate) {
    final currentMap = _asMap(current);
    if (currentMap.isNotEmpty) {
      return current;
    }
    final candidateMap = _asMap(candidate);
    return candidateMap.isNotEmpty ? candidate : current;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  static String? _asNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    return null;
  }

  static int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}

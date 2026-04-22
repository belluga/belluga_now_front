import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/partners/projections/partner_profile_module_data.dart';
import 'package:belluga_now/domain/partners/projections/value_objects/partner_projection_text_values.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_taxonomy_filter.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:belluga_now/infrastructure/services/location_origin_resolution_request_factory.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class LaravelAccountProfilesBackend implements AccountProfilesBackendContract {
  LaravelAccountProfilesBackend({
    Dio? dio,
    LocationOriginServiceContract? locationOriginService,
  })  : _dio = dio ?? Dio(),
        _locationOriginService = locationOriginService;

  final Dio _dio;
  LocationOriginServiceContract? _locationOriginService;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  LocationOriginServiceContract? get _resolvedLocationOriginService {
    if (_locationOriginService != null) {
      return _locationOriginService;
    }
    if (!GetIt.I.isRegistered<LocationOriginServiceContract>()) {
      return null;
    }
    _locationOriginService = GetIt.I.get<LocationOriginServiceContract>();
    return _locationOriginService;
  }

  Future<Map<String, String>> _buildHeaders({bool includeJsonAccept = false}) {
    return TenantPublicAuthHeaders.build(
      includeJsonAccept: includeJsonAccept,
      bootstrapIfEmpty: true,
    );
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
    List<String>? allowedTypes,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'per_page': pageSize,
      };
      final trimmedQuery = query?.trim();
      if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
        queryParameters['search'] = trimmedQuery;
      }
      final normalizedTypes = _normalizeTypeFilters(
        typeFilter: typeFilter,
        typeFilters: typeFilters,
      );
      if (normalizedTypes.isNotEmpty) {
        final queryValue = normalizedTypes.length == 1
            ? normalizedTypes.single
            : normalizedTypes;
        queryParameters['profile_type'] = queryValue;
        queryParameters['filter'] = <String, dynamic>{
          'profile_type': queryValue,
        };
      }
      _appendTaxonomyQueryParameters(queryParameters, taxonomyFilters);

      final headers = await _buildHeaders(includeJsonAccept: true);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles',
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profiles response shape.');
      }
      final data = _extractDataList(raw);

      final currentPage = _parsePageValue(raw['current_page']) ?? page;
      final lastPage = _parsePageValue(raw['last_page']);
      final hasMore = lastPage != null
          ? currentPage < lastPage
          : raw['next_page_url'] != null;

      final distanceOrigin = await _resolveDistanceOrigin();
      return pagedAccountProfilesResultFromRaw(
        profiles: _parseProfiles(data, distanceOrigin: distanceOrigin),
        hasMore: hasMore,
      );
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load account profiles '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) async {
    final origin = await _resolveEffectiveOriginCoordinate();
    if (origin == null) {
      return const <AccountProfileModel>[];
    }

    final safePageSize = pageSize <= 0 ? 10 : pageSize.clamp(1, 50);
    try {
      final headers = await _buildHeaders(includeJsonAccept: true);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/near',
        queryParameters: _nearQueryParameters(
          originLat: origin.latitude,
          originLng: origin.longitude,
          page: 1,
          pageSize: safePageSize,
          typeFilters: typeFilters,
          taxonomyFilters: taxonomyFilters,
        ),
        options: Options(headers: headers),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profiles near response shape.');
      }

      final data = _extractDataList(raw);
      return _parseProfiles(data, distanceOrigin: origin);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load nearby account profiles '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  Map<String, dynamic> _nearQueryParameters({
    required double originLat,
    required double originLng,
    required int page,
    required int pageSize,
    List<String>? typeFilters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  }) {
    final queryParameters = <String, dynamic>{
      'origin_lat': originLat,
      'origin_lng': originLng,
      'page': page,
      'page_size': pageSize,
    };
    final normalizedTypes = _normalizeTypeFilters(typeFilters: typeFilters);
    if (normalizedTypes.isNotEmpty) {
      queryParameters['profile_type'] = normalizedTypes.length == 1
          ? normalizedTypes.single
          : normalizedTypes;
    }
    _appendTaxonomyQueryParameters(queryParameters, taxonomyFilters);

    return queryParameters;
  }

  List<String> _normalizeTypeFilters({
    String? typeFilter,
    List<String>? typeFilters,
  }) {
    return <String>{
      if (typeFilter != null && typeFilter.trim().isNotEmpty) typeFilter.trim(),
      for (final filter in typeFilters ?? const <String>[])
        if (filter.trim().isNotEmpty) filter.trim(),
    }.toList(growable: false);
  }

  void _appendTaxonomyQueryParameters(
    Map<String, dynamic> queryParameters,
    List<AccountProfilesRepositoryTaxonomyFilter>? taxonomyFilters,
  ) {
    final normalized = <AccountProfilesRepositoryTaxonomyFilter>[];
    final seen = <String>{};
    for (final filter in taxonomyFilters ?? const []) {
      if (!filter.isValid) {
        continue;
      }
      final key = '${filter.type.value}:${filter.term.value}';
      if (seen.add(key)) {
        normalized.add(filter);
      }
    }

    for (var index = 0; index < normalized.length; index += 1) {
      final filter = normalized[index];
      queryParameters['taxonomy[$index][type]'] = filter.type.value;
      queryParameters['taxonomy[$index][value]'] = filter.term.value;
    }
  }

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async {
    final normalizedSlug = slug.trim();
    if (normalizedSlug.isEmpty) {
      return null;
    }

    try {
      final headers = await _buildHeaders(includeJsonAccept: true);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/'
        '${Uri.encodeComponent(normalizedSlug)}',
        options: Options(headers: headers),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profile detail response shape.');
      }

      final data = raw['data'];
      if (data is! Map) {
        throw Exception('Account profile detail payload missing data object.');
      }

      final distanceOrigin = await _resolveDistanceOrigin();
      final profiles = _parseProfiles(
        [Map<String, dynamic>.from(data)],
        distanceOrigin: distanceOrigin,
      );
      if (profiles.isEmpty) {
        throw Exception(
          'Account profile detail payload missing required fields.',
        );
      }

      return profiles.first;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }

      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      throw Exception(
        'Failed to load account profile by slug '
        '[status=$statusCode] '
        '(${error.requestOptions.uri}): '
        '${data ?? error.message}',
      );
    }
  }

  List<AccountProfileModel> _parseProfiles(
    List<dynamic> raw, {
    required CityCoordinate? distanceOrigin,
  }) {
    final profiles = <AccountProfileModel>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final id = json['id']?.toString();
      final name = json['display_name']?.toString();
      final slug = json['slug']?.toString();
      final typeRaw = json['profile_type']?.toString();
      if (id == null || name == null || slug == null || typeRaw == null) {
        continue;
      }
      final trimmedType = typeRaw.trim();
      if (trimmedType.isEmpty) continue;
      final tags = _extractTags(json['taxonomy_terms']);
      final agendaEvents = _extractAgendaEvents(json['agenda_occurrences']);
      final distanceMeters = _resolveDistanceMeters(
        json,
        distanceOrigin: distanceOrigin,
      );
      final locationCoordinates =
          _parseLocationLatLng(json['location']) ?? _parseTopLevelLatLng(json);
      final locationAddress = _parseLocationAddress(json);
      ThumbUriValue? avatarValue;
      final avatarUrl = json['avatar_url']?.toString();
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        avatarValue = ThumbUriValue(defaultValue: Uri.parse(avatarUrl))
          ..parse(avatarUrl);
      }
      ThumbUriValue? coverValue;
      final coverUrl = json['cover_url']?.toString();
      if (coverUrl != null && coverUrl.isNotEmpty) {
        coverValue = ThumbUriValue(defaultValue: Uri.parse(coverUrl))
          ..parse(coverUrl);
      }
      DescriptionValue? bioValue;
      final bio = json['bio']?.toString();
      if (bio != null && bio.isNotEmpty) {
        bioValue = DescriptionValue()..parse(bio);
      }
      DescriptionValue? contentValue;
      final content = json['content']?.toString();
      if (content != null && content.isNotEmpty) {
        contentValue = DescriptionValue()..parse(content);
      }
      AccountProfileLocationAddressValue? locationAddressValue;
      if (locationAddress != null) {
        locationAddressValue = AccountProfileLocationAddressValue()
          ..parse(locationAddress);
      }
      LatitudeValue? locationLatitudeValue;
      LongitudeValue? locationLongitudeValue;
      if (locationCoordinates != null) {
        locationLatitudeValue = LatitudeValue()
          ..parse(locationCoordinates.$1.toString());
        locationLongitudeValue = LongitudeValue()
          ..parse(locationCoordinates.$2.toString());
      }
      profiles.add(
        AccountProfileModel(
          idValue: MongoIDValue()..parse(id),
          nameValue: TitleValue()..parse(name),
          slugValue: SlugValue()..parse(slug),
          profileTypeValue: AccountProfileTypeValue(trimmedType),
          avatarValue: avatarValue,
          coverValue: coverValue,
          bioValue: bioValue,
          contentValue: contentValue,
          tagValues:
              tags.map(AccountProfileTagValue.new).toList(growable: false),
          agendaEventViews: agendaEvents,
          distanceMetersValue:
              AccountProfileDistanceMetersValue(distanceMeters),
          locationAddressValue: locationAddressValue,
          locationLatitudeValue: locationLatitudeValue,
          locationLongitudeValue: locationLongitudeValue,
        ),
      );
    }
    return profiles;
  }

  List<dynamic> _extractDataList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is List) {
      return data;
    }

    final items = payload['items'];
    if (items is List) {
      return items;
    }

    throw Exception('Account profiles payload missing data list.');
  }

  List<String> _extractTags(dynamic raw) {
    if (raw is! List) return const [];
    final tags = <String>[];
    for (final entry in raw) {
      if (entry is Map) {
        final value = entry['name']?.toString() ??
            entry['label']?.toString() ??
            entry['value']?.toString();
        if (value != null && value.trim().isNotEmpty) {
          tags.add(value.trim());
        }
      }
    }
    return tags;
  }

  List<PartnerEventView> _extractAgendaEvents(dynamic raw) {
    if (raw is! List) return const [];
    final agendaEvents = <PartnerEventView>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final eventId = json['event_id']?.toString().trim() ?? '';
      final occurrenceId = json['occurrence_id']?.toString().trim() ?? '';
      final slug = json['slug']?.toString().trim() ?? '';
      final title = json['title']?.toString().trim() ?? '';
      final startRaw =
          (json['date_time_start'] ?? json['starts_at'])?.toString().trim() ??
              '';
      if (eventId.isEmpty ||
          occurrenceId.isEmpty ||
          slug.isEmpty ||
          title.isEmpty ||
          startRaw.isEmpty) {
        continue;
      }

      final startDateTimeValue = DateTimeValue(isRequired: true)
        ..parse(startRaw);
      final endRaw =
          (json['date_time_end'] ?? json['ends_at'])?.toString().trim() ?? '';
      final endDateTimeValue = endRaw.isEmpty
          ? null
          : (DateTimeValue(isRequired: true)..parse(endRaw));
      final venueId = _extractAgendaVenueId(json);
      final venueTitle = _extractAgendaVenueTitle(json);
      final eventTypeLabel = _extractAgendaEventTypeLabel(json);
      final locationLabel =
          _extractAgendaLocationLabel(json) ?? venueTitle ?? '';
      final linkedAccountProfiles =
          _extractAgendaLinkedAccountProfiles(json['linked_account_profiles']);
      ThumbUriValue? imageUriValue;
      final imageUrl = _extractAgendaImageUrl(
        json,
        linkedAccountProfiles,
      );
      if (imageUrl != null && imageUrl.isNotEmpty) {
        imageUriValue = ThumbUriValue(defaultValue: Uri.parse(imageUrl))
          ..parse(imageUrl);
      }

      agendaEvents.add(
        PartnerEventView(
          eventIdValue: MongoIDValue()..parse(eventId),
          occurrenceIdValue: MongoIDValue()..parse(occurrenceId),
          slugValue: SlugValue()..parse(slug),
          titleValue: partnerProjectionRequiredText(title),
          eventTypeLabelValue: eventTypeLabel == null
              ? null
              : partnerProjectionOptionalText(eventTypeLabel),
          startDateTimeValue: startDateTimeValue,
          endDateTimeValue: endDateTimeValue,
          locationValue: partnerProjectionRequiredText(locationLabel),
          venueIdValue:
              venueId == null ? null : (MongoIDValue()..parse(venueId)),
          venueTitleValue: venueTitle == null
              ? null
              : partnerProjectionOptionalText(venueTitle),
          imageUriValue: imageUriValue,
          linkedAccountProfiles: linkedAccountProfiles,
        ),
      );
    }
    return agendaEvents;
  }

  List<PartnerSupportedEntityView> _extractAgendaLinkedAccountProfiles(
    dynamic raw,
  ) {
    if (raw is! List) {
      return const [];
    }

    final linkedAccountProfiles = <PartnerSupportedEntityView>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final json = Map<String, dynamic>.from(entry);
      final displayName =
          (json['display_name'] ?? json['name'])?.toString().trim() ?? '';
      if (displayName.isEmpty) {
        continue;
      }

      final thumb = json['avatar_url']?.toString().trim();
      linkedAccountProfiles.add(
        PartnerSupportedEntityView(
          idValue: (() {
            final id = json['id']?.toString().trim();
            if (id == null || id.isEmpty) {
              return null;
            }
            return MongoIDValue()..parse(id);
          })(),
          titleValue: partnerProjectionRequiredText(displayName),
          thumbValue: thumb == null || thumb.isEmpty
              ? null
              : partnerProjectionOptionalText(thumb),
        ),
      );
    }

    return linkedAccountProfiles;
  }

  String? _extractAgendaVenueId(Map<String, dynamic> json) {
    final rawVenue = json['venue'];
    if (rawVenue is! Map) {
      return null;
    }

    final venue = Map<String, dynamic>.from(rawVenue);
    final value = venue['id']?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? _extractAgendaVenueTitle(Map<String, dynamic> json) {
    final rawVenue = json['venue'];
    if (rawVenue is! Map) {
      return null;
    }

    final venue = Map<String, dynamic>.from(rawVenue);
    final value = (venue['display_name'] ?? venue['name'])?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? _extractAgendaEventTypeLabel(Map<String, dynamic> json) {
    final rawType = json['type'];
    if (rawType is! Map) {
      return null;
    }

    final type = Map<String, dynamic>.from(rawType);
    final value =
        (type['label'] ?? type['name'] ?? type['title'])?.toString().trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? _extractAgendaLocationLabel(Map<String, dynamic> json) {
    final rawLocation = json['location'];
    if (rawLocation is String) {
      final value = rawLocation.trim();
      return value.isEmpty ? null : value;
    }
    if (rawLocation is! Map) {
      return null;
    }

    final location = Map<String, dynamic>.from(rawLocation);
    const keys = <String>[
      'label',
      'display_name',
      'formatted_address',
      'address',
      'name',
    ];
    for (final key in keys) {
      final value = location[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String? _extractAgendaImageUrl(
    Map<String, dynamic> json,
    List<PartnerSupportedEntityView> linkedAccountProfiles,
  ) {
    final rawThumb = json['thumb'];
    if (rawThumb is Map) {
      final thumb = Map<String, dynamic>.from(rawThumb);
      final data = thumb['data'];
      if (data is Map) {
        final url = data['url']?.toString().trim();
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
    }

    for (final counterpart in linkedAccountProfiles) {
      final imageUrl = counterpart.thumb?.trim();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }

    final rawVenue = json['venue'];
    if (rawVenue is Map) {
      final venue = Map<String, dynamic>.from(rawVenue);
      for (final key in const ['hero_image_url', 'logo_url']) {
        final imageUrl = venue[key]?.toString().trim();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
    }

    return null;
  }

  int? _parsePageValue(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  double? _resolveDistanceMeters(
    Map<String, dynamic> json, {
    required CityCoordinate? distanceOrigin,
  }) {
    final directDistance = _parseDirectDistanceMeters(json);
    if (directDistance != null) {
      return directDistance;
    }

    final location =
        _parseLocationLatLng(json['location']) ?? _parseTopLevelLatLng(json);
    if (location == null) {
      return null;
    }

    if (distanceOrigin == null) {
      return null;
    }

    return haversineDistanceMeters(
      coordinateA: distanceOrigin,
      coordinateB: CityCoordinate.fromLatLng(
        LatLng(location.$1, location.$2),
      ),
    ).value;
  }

  String? _parseLocationAddress(Map<String, dynamic> json) {
    final topLevelAddress = json['address']?.toString().trim();
    if (topLevelAddress != null && topLevelAddress.isNotEmpty) {
      return topLevelAddress;
    }

    final rawLocation = json['location'];
    if (rawLocation is! Map) {
      return null;
    }

    final location = Map<String, dynamic>.from(rawLocation);
    const addressKeys = <String>[
      'address',
      'label',
      'formatted_address',
      'display_name',
      'name',
    ];
    for (final key in addressKeys) {
      final value = location[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  double? _parseDirectDistanceMeters(Map<String, dynamic> json) {
    const meterKeys = <String>[
      'distance_meters',
      'distanceMeters',
      'distance_in_meters',
      'distanceMetersValue',
    ];
    for (final key in meterKeys) {
      final value = _parseDouble(json[key]);
      if (value != null) {
        return value;
      }
    }

    final distanceKm =
        _parseDouble(json['distance_km']) ?? _parseDouble(json['distanceKm']);
    if (distanceKm != null) {
      return distanceKm * 1000;
    }
    return null;
  }

  Future<CityCoordinate?> _resolveEffectiveOriginCoordinate() async {
    final locationOriginService = _resolvedLocationOriginService;
    if (locationOriginService == null) {
      return null;
    }
    final resolution = await locationOriginService.resolve(
      LocationOriginResolutionRequestFactory.create(
        warmUpIfPossible: true,
      ),
    );
    return resolution.effectiveCoordinate;
  }

  Future<CityCoordinate?> _resolveDistanceOrigin() async {
    return _resolveEffectiveOriginCoordinate();
  }

  (double, double)? _parseLocationLatLng(dynamic rawLocation) {
    if (rawLocation is List) {
      return _parseCoordinatesPayload(rawLocation);
    }
    if (rawLocation is! Map) {
      return null;
    }
    final location = Map<String, dynamic>.from(rawLocation);
    final directLatLng = _parseLatLngFromMap(location);
    if (directLatLng != null) {
      return directLatLng;
    }

    final geoLatLng = _parseCoordinatesPayload(location['geo']);
    if (geoLatLng != null) {
      return geoLatLng;
    }

    final locationCoordinates =
        _parseCoordinatesPayload(location['coordinates']);
    if (locationCoordinates != null) {
      return locationCoordinates;
    }

    return null;
  }

  (double, double)? _parseTopLevelLatLng(Map<String, dynamic> json) {
    final topLevelLatLng = _parseLatLngFromMap(json);
    if (topLevelLatLng != null) {
      return topLevelLatLng;
    }
    return _parseCoordinatesPayload(json['coordinates']);
  }

  (double, double)? _parseLatLngFromMap(Map<String, dynamic> map) {
    final lat = _parseDouble(map['lat']) ?? _parseDouble(map['latitude']);
    final lng = _parseDouble(map['lng']) ??
        _parseDouble(map['lon']) ??
        _parseDouble(map['longitude']);
    if (lat != null && lng != null) {
      return (lat, lng);
    }
    return null;
  }

  (double, double)? _parseCoordinatesPayload(dynamic coordinatesRaw) {
    if (coordinatesRaw is List && coordinatesRaw.length >= 2) {
      final coordLng = _parseDouble(coordinatesRaw[0]);
      final coordLat = _parseDouble(coordinatesRaw[1]);
      if (coordLat != null && coordLng != null) {
        return (coordLat, coordLng);
      }
      return null;
    }
    if (coordinatesRaw is Map) {
      final coordinates = Map<String, dynamic>.from(coordinatesRaw);
      final latLng = _parseLatLngFromMap(coordinates);
      if (latLng != null) {
        return latLng;
      }
      return _parseCoordinatesPayload(coordinates['coordinates']);
    }
    return null;
  }

  double? _parseDouble(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      final normalized = raw.trim().replaceAll(',', '.');
      if (normalized.isEmpty) {
        return null;
      }
      return double.tryParse(normalized);
    }
    return null;
  }
}

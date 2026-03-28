import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_fields.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class LaravelAccountProfilesBackend implements AccountProfilesBackendContract {
  LaravelAccountProfilesBackend({Dio? dio}) : _dio = dio ?? Dio();

  static const int _defaultPageSize = 30;
  static const int _maxPages = 10;

  final Dio _dio;

  String get _apiBaseUrl =>
      '${GetIt.I.get<AppData>().mainDomainValue.value.origin}/api';

  Future<Map<String, String>> _buildHeaders({bool includeJsonAccept = false}) {
    return TenantPublicAuthHeaders.build(
      includeJsonAccept: includeJsonAccept,
      bootstrapIfEmpty: true,
    );
  }

  @override
  Future<List<AccountProfileModel>> fetchAccountProfiles() async {
    final page = await fetchAccountProfilesPage(
      page: 1,
      pageSize: _defaultPageSize,
    );

    return page.profiles;
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
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
      final trimmedType = typeFilter?.trim();
      if (trimmedType != null && trimmedType.isNotEmpty) {
        queryParameters['profile_type'] = trimmedType;
        queryParameters['filter'] = <String, dynamic>{
          'profile_type': trimmedType,
        };
      }

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

      return PagedAccountProfilesResult(
        profiles: _parseProfiles(data),
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
  }) async {
    final origin = await _effectiveOriginLatLng();
    if (origin == null) {
      return const <AccountProfileModel>[];
    }

    final safePageSize = pageSize <= 0 ? 10 : pageSize.clamp(1, 50);
    try {
      final headers = await _buildHeaders(includeJsonAccept: true);
      final response = await _dio.get(
        '$_apiBaseUrl/v1/account_profiles/near',
        queryParameters: <String, dynamic>{
          'origin_lat': origin.$1,
          'origin_lng': origin.$2,
          'page': 1,
          'page_size': safePageSize,
        },
        options: Options(headers: headers),
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw Exception('Unexpected account profiles near response shape.');
      }

      final data = _extractDataList(raw);
      return _parseProfiles(data);
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

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    String? query,
    String? typeFilter,
    List<String>? allowedTypes,
  }) async {
    final profiles = <AccountProfileModel>[];
    var page = 1;
    var hasMore = true;

    while (hasMore && page <= _maxPages) {
      final result = await fetchAccountProfilesPage(
        page: page,
        pageSize: _defaultPageSize,
        query: query,
        typeFilter: typeFilter,
        allowedTypes: allowedTypes,
      );
      profiles.addAll(result.profiles);
      hasMore = result.hasMore;
      page += 1;
    }

    return profiles;
  }

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) async {
    final profiles = await fetchAccountProfiles();
    try {
      return profiles.firstWhere((profile) => profile.slug == slug);
    } catch (_) {
      return null;
    }
  }

  List<AccountProfileModel> _parseProfiles(List<dynamic> raw) {
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
      final distanceMeters = _resolveDistanceMeters(json);
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
      profiles.add(
        AccountProfileModel(
          idValue: MongoIDValue()..parse(id),
          nameValue: TitleValue()..parse(name),
          slugValue: SlugValue()..parse(slug),
          profileTypeValue: AccountProfileTypeValue(trimmedType),
          avatarValue: avatarValue,
          coverValue: coverValue,
          bioValue: bioValue,
          tagsValue: AccountProfileTagsValue(tags),
          distanceMetersValue:
              AccountProfileDistanceMetersValue(distanceMeters),
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
        final value = entry['value']?.toString();
        if (value != null && value.trim().isNotEmpty) {
          tags.add(value);
        }
      }
    }
    return tags;
  }

  int? _parsePageValue(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  double? _resolveDistanceMeters(Map<String, dynamic> json) {
    final directDistance = _parseDirectDistanceMeters(json);
    if (directDistance != null) {
      return directDistance;
    }

    final location =
        _parseLocationLatLng(json['location']) ?? _parseTopLevelLatLng(json);
    if (location == null) {
      return null;
    }

    final origin = _effectiveDistanceOriginLatLng();
    if (origin == null) {
      return null;
    }

    return haversineDistanceMeters(
      lat1: origin.$1,
      lon1: origin.$2,
      lat2: location.$1,
      lon2: location.$2,
    );
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

  (double, double)? _effectiveDistanceOriginLatLng() {
    return _tenantDefaultOriginLatLng();
  }

  Future<(double, double)?> _effectiveOriginLatLng() async {
    return (await _userLocationLatLng()) ?? _tenantDefaultOriginLatLng();
  }

  Future<(double, double)?> _userLocationLatLng() async {
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      return null;
    }
    final repository = GetIt.I.get<UserLocationRepositoryContract>();
    try {
      await repository.ensureLoaded();
    } catch (_) {
      // Keep a best-effort path; fallback to tenant default origin below.
    }
    final coordinate = repository.userLocationStreamValue.value ??
        repository.lastKnownLocationStreamValue.value;
    if (coordinate == null) {
      return null;
    }
    return (coordinate.latitude, coordinate.longitude);
  }

  (double, double)? _tenantDefaultOriginLatLng() {
    if (!GetIt.I.isRegistered<AppData>()) {
      return null;
    }
    final origin = GetIt.I.get<AppData>().tenantDefaultOrigin;
    if (origin == null) {
      return null;
    }
    return (origin.latitude, origin.longitude);
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

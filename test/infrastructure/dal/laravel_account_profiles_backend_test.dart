import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_text_value.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/partners_backend/laravel_account_profiles_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );
    _registerAppData();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('fetchAccountProfiles hits account_profiles and parses profiles',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'taxonomy_terms': [
              {'type': 'genre', 'value': 'indie'},
            ],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profiles = await backend.fetchAccountProfiles();

    expect(adapter.lastRequest?.uri.path, '/api/v1/account_profiles');
    expect(adapter.lastRequest?.queryParameters['page'], 1);
    expect(adapter.lastRequest?.queryParameters['per_page'], 30);
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer test-token');
    expect(profiles, hasLength(1));
    expect(profiles.first.name, 'Artist One');
    expect(profiles.first.slug, 'artist-one');
  });

  test('fetchAccountProfiles bootstraps auth token when empty', () async {
    final authRepository = GetIt.I.get<AuthRepositoryContract<UserContract>>()
        as _FakeAuthRepository;
    authRepository.setUserToken(authRepoString(''));

    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    await backend.fetchAccountProfiles();

    expect(authRepository.initCallCount, 1);
    expect(
      adapter.lastRequest?.headers['Authorization'],
      'Bearer refreshed-token',
    );
  });

  test('fetchAccountProfiles parses direct distance meters field', () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Nearby Venue',
            'slug': 'nearby-venue',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'distance_meters': 1425.75,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profiles = await backend.fetchAccountProfiles();

    expect(profiles, hasLength(1));
    expect(profiles.first.distanceMeters, closeTo(1425.75, 0.001));
  });

  test(
      'fetchAccountProfilesPage keeps profile_type unset when no explicit type filter',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
        'current_page': 1,
        'last_page': 1,
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
      allowedTypes: const ['artist', 'venue'],
    );

    expect(adapter.lastRequest?.uri.path, '/api/v1/account_profiles');
    expect(adapter.lastRequest?.queryParameters.containsKey('profile_type'),
        isFalse);
    expect(adapter.lastRequest?.queryParameters.containsKey('filter'), isFalse);
  });

  test('fetchAccountProfiles computes distance using tenant default origin',
      () async {
    _registerAppData(
        defaultOriginLat: -20.670000, defaultOriginLng: -40.500000);
    final validId = _generateMongoId();
    final targetLat = -20.664500;
    final targetLng = -40.494200;
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Computed Distance',
            'slug': 'computed-distance',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'location': {
              'lat': targetLat,
              'lng': targetLng,
            },
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profiles = await backend.fetchAccountProfiles();

    expect(profiles, hasLength(1));
    final expected = haversineDistanceMeters(
      coordinateA: _coordinate(lat: -20.670000, lng: -40.500000),
      coordinateB: _coordinate(lat: targetLat, lng: targetLng),
    );
    expect(profiles.first.distanceMeters, closeTo(expected.value, 0.001));
  });

  test('fetchNearbyAccountProfiles calls near endpoint with origin', () async {
    _registerAppData(
      defaultOriginLat: -20.670000,
      defaultOriginLng: -40.500000,
    );
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'page': 1,
        'page_size': 5,
        'has_more': false,
        'data': [
          {
            'id': validId,
            'display_name': 'Nearby Venue',
            'slug': 'nearby-venue',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'distance_meters': 240.0,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profiles = await backend.fetchNearbyAccountProfiles(pageSize: 5);

    expect(adapter.lastRequest?.uri.path, '/api/v1/account_profiles/near');
    expect(adapter.lastRequest?.queryParameters['origin_lat'], -20.67);
    expect(adapter.lastRequest?.queryParameters['origin_lng'], -40.5);
    expect(adapter.lastRequest?.queryParameters['page'], 1);
    expect(adapter.lastRequest?.queryParameters['page_size'], 5);
    expect(profiles, hasLength(1));
    expect(profiles.first.name, 'Nearby Venue');
    expect(profiles.first.distanceMeters, closeTo(240.0, 0.001));
  });

  test(
      'fetchNearbyAccountProfiles ensures user location snapshot before resolving origin',
      () async {
    _registerAppData(
      defaultOriginLat: null,
      defaultOriginLng: null,
    );
    final userLocationRepository = _FakeUserLocationRepository(
      loadedCoordinate: _coordinate(lat: -20.661, lng: -40.492),
    );
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      userLocationRepository,
    );

    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'page': 1,
        'page_size': 5,
        'has_more': false,
        'data': [
          {
            'id': validId,
            'display_name': 'Nearby Artist',
            'slug': 'nearby-artist',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'distance_meters': 120.0,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
        userLocationRepository: userLocationRepository,
      ),
    );

    final profiles = await backend.fetchNearbyAccountProfiles(pageSize: 5);

    expect(adapter.lastRequest?.uri.path, '/api/v1/account_profiles/near');
    expect(adapter.lastRequest?.queryParameters['origin_lat'], -20.661);
    expect(adapter.lastRequest?.queryParameters['origin_lng'], -40.492);
    expect(profiles, hasLength(1));
    expect(profiles.first.distanceMeters, closeTo(120.0, 0.001));
  });
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(AppData appData)
      : _appData = appData,
        maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
          defaultValue: DistanceInMetersValue.fromRaw(
            appData.mapRadiusMaxMeters,
            defaultValue: appData.mapRadiusMaxMeters,
          ),
        );

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  String _token = 'test-token';
  int initCallCount = 0;

  @override
  BackendContract get backend => throw UnimplementedError();

  @override
  String get userToken => _token;

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {
    _token = token?.value ?? '';
  }

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => true;

  @override
  bool get isAuthorized => true;

  @override
  Future<void> init() async {
    initCallCount += 1;
    if (_token.trim().isEmpty) {
      _token = 'refreshed-token';
    }
  }

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({required Map<String, dynamic> response})
      : _response = response;

  final Map<String, dynamic> _response;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(_response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FakeUserLocationRepository extends UserLocationRepositoryContract {
  _FakeUserLocationRepository({
    required this.loadedCoordinate,
  });

  final CityCoordinate loadedCoordinate;
  int ensureLoadedCalls = 0;

  @override
  final userLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownCapturedAtStreamValue = StreamValue<DateTime?>();

  @override
  final lastKnownAccuracyStreamValue = StreamValue<double?>();

  @override
  final lastKnownAddressStreamValue = StreamValue<String?>();

  @override
  final locationResolutionPhaseStreamValue =
      StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {
    ensureLoadedCalls += 1;
    lastKnownLocationStreamValue.addValue(loadedCoordinate);
  }

  @override
  Future<void> setLastKnownAddress(
    UserLocationRepositoryContractTextValue? address,
  ) async {}

  @override
  Future<bool> warmUpIfPermitted() async {
    lastKnownLocationStreamValue.addValue(loadedCoordinate);
    return true;
  }

  @override
  Future<bool> refreshIfPermitted({
    UserLocationRepositoryContractDurationValue? minInterval,
  }) async =>
      true;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      true;

  @override
  Future<void> stopTracking() async {}
}

CityCoordinate _coordinate({
  required double lat,
  required double lng,
}) {
  return CityCoordinate(
    latitudeValue: LatitudeValue()..parse(lat.toString()),
    longitudeValue: LongitudeValue()..parse(lng.toString()),
  );
}

AppData _buildAppDataWithSettings({
  double? defaultOriginLat,
  double? defaultOriginLng,
}) {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
    'settings': {
      'map_ui': {
        if (defaultOriginLat != null && defaultOriginLng != null)
          'default_origin': {
            'lat': defaultOriginLat,
            'lng': defaultOriginLng,
          },
      },
    },
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
      remoteData: remoteData, localInfo: localInfo);
}

void _registerAppData({
  double? defaultOriginLat,
  double? defaultOriginLng,
}) {
  if (GetIt.I.isRegistered<AppData>()) {
    GetIt.I.unregister<AppData>();
  }
  GetIt.I.registerSingleton<AppData>(
    _buildAppDataWithSettings(
      defaultOriginLat: defaultOriginLat,
      defaultOriginLng: defaultOriginLng,
    ),
  );
}

String _generateMongoId() {
  // 24-char hex string to satisfy MongoIDValue validation in AccountProfileModel.
  return DateTime.now()
      .microsecondsSinceEpoch
      .toRadixString(16)
      .padLeft(24, '0')
      .substring(0, 24);
}

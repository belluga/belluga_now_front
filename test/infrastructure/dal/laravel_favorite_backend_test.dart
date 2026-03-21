import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/favorite_backend/laravel_favorite_backend.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('fetchFavorites uses favorites contract with pagination and auth',
      () async {
    final adapter = _FavoritesApiAdapter();
    final dio = Dio()..httpClientAdapter = adapter;

    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(userTokenValue: 'test-token'),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());

    final backend = LaravelFavoriteBackend(dio: dio);
    final favorites = await backend.fetchFavorites();

    expect(favorites, hasLength(2));
    expect(favorites.first.id, 'profile-1');
    expect(favorites.first.slug, 'profile-1');
    expect(favorites.first.registryKey, 'account_profile');
    expect(favorites.first.targetType, 'account_profile');
    expect(favorites.first.nextEventOccurrenceAt, isNotNull);
    expect(favorites[1].id, 'profile-2');

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.uri.path, '/api/v1/favorites');
    expect(adapter.requests.first.queryParameters['page'], 1);
    expect(adapter.requests.first.queryParameters['page_size'], 30);
    expect(adapter.requests.first.queryParameters['registry_key'],
        'account_profile');
    expect(adapter.requests.first.queryParameters['target_type'],
        'account_profile');
    expect(
      adapter.requests.first.headers['Authorization'],
      'Bearer test-token',
    );
  });

  test('fetchFavorites returns empty and skips HTTP when token is missing',
      () async {
    final adapter = _FavoritesApiAdapter();
    final dio = Dio()..httpClientAdapter = adapter;

    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(userTokenValue: ''),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());

    final backend = LaravelFavoriteBackend(dio: dio);
    final favorites = await backend.fetchFavorites();

    expect(favorites, isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('favoriteAccountProfile posts canonical payload', () async {
    final adapter = _FavoritesApiAdapter();
    final dio = Dio()..httpClientAdapter = adapter;

    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(userTokenValue: 'test-token'),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());

    final backend = LaravelFavoriteBackend(dio: dio);
    await backend.favoriteAccountProfile('profile-123');

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.first;
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/v1/favorites');
    expect(
      request.headers['Authorization'],
      'Bearer test-token',
    );
    expect(
      request.data,
      {
        'target_id': 'profile-123',
        'registry_key': 'account_profile',
        'target_type': 'account_profile',
      },
    );
  });

  test('unfavoriteAccountProfile deletes canonical payload', () async {
    final adapter = _FavoritesApiAdapter();
    final dio = Dio()..httpClientAdapter = adapter;

    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(userTokenValue: 'test-token'),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());

    final backend = LaravelFavoriteBackend(dio: dio);
    await backend.unfavoriteAccountProfile('profile-123');

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.first;
    expect(request.method, 'DELETE');
    expect(request.uri.path, '/api/v1/favorites');
    expect(
      request.data,
      {
        'target_id': 'profile-123',
        'registry_key': 'account_profile',
        'target_type': 'account_profile',
      },
    );
  });
}

class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.uri,
    required this.queryParameters,
    required this.headers,
    required this.data,
  });

  final String method;
  final Uri uri;
  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> headers;
  final Object? data;
}

class _FavoritesApiAdapter implements HttpClientAdapter {
  final List<_RecordedRequest> requests = <_RecordedRequest>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _RecordedRequest(
        method: options.method,
        uri: options.uri,
        queryParameters: Map<String, dynamic>.from(options.queryParameters),
        headers: Map<String, dynamic>.from(options.headers),
        data: options.data,
      ),
    );

    if (options.method == 'POST' || options.method == 'DELETE') {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {'is_favorite': options.method == 'POST'},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }

    final page = options.queryParameters['page'];
    final pageNumber = page is int ? page : int.tryParse(page.toString()) ?? 1;

    Map<String, Object?> payload;
    if (pageNumber == 1) {
      payload = {
        'data': {
          'items': [
            {
              'registry_key': 'account_profile',
              'target_type': 'account_profile',
              'target_id': 'profile-1',
              'favorited_at': '2026-03-20T10:00:00Z',
              'target': {
                'id': 'profile-1',
                'slug': 'profile-1',
                'display_name': 'Profile One',
                'avatar_url': 'https://cdn.test/profile-1.png',
              },
              'snapshot': {
                'next_event_occurrence_id': 'occ-1',
                'next_event_occurrence_at': '2026-03-22T20:00:00Z',
                'last_event_occurrence_at': null,
              },
              'navigation': {
                'kind': 'account_profile',
                'target_slug': 'profile-1',
              },
            },
          ],
          'has_more': true,
        },
      };
    } else {
      payload = {
        'data': {
          'items': [
            {
              'registry_key': 'account_profile',
              'target_type': 'account_profile',
              'target_id': 'profile-2',
              'favorited_at': '2026-03-19T08:00:00Z',
              'target': {
                'id': 'profile-2',
                'slug': 'profile-2',
                'display_name': 'Profile Two',
                'avatar_url': null,
              },
              'snapshot': {
                'next_event_occurrence_id': null,
                'next_event_occurrence_at': null,
                'last_event_occurrence_at': '2026-03-18T20:00:00Z',
              },
              'navigation': {
                'kind': 'account_profile',
                'target_slug': 'profile-2',
              },
            },
          ],
          'has_more': false,
        },
      };
    }

    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    required this.userTokenValue,
  });

  final String userTokenValue;

  @override
  BackendContract get backend => throw UnimplementedError();

  @override
  String get userToken => userTokenValue;

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => true;

  @override
  bool get isAuthorized => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
      String newPassword, String confirmPassword) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUser(Map<String, Object?> data) async {}
}

AppData _buildAppData() {
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
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return AppData.fromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

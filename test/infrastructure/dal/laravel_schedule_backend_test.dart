import 'dart:async';
import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/schedule_backend/laravel_schedule_backend.dart';
import 'package:belluga_now/infrastructure/services/sse/sse_client.dart';
import 'package:belluga_now/infrastructure/services/sse/sse_message.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
      'watchEventsStream serializes taxonomy as array fields and forwards auth',
      () {
    final sseClient = _RecordingSseClient();
    final backend = LaravelScheduleBackend(
      dio: Dio()..httpClientAdapter = _NoopAdapter(),
      sseClient: sseClient,
    );

    backend.watchEventsStream(
      showPastOnly: true,
      confirmedOnly: true,
      categories: const ['music'],
      tags: const ['live'],
      taxonomy: const [
        {'type': 'genre', 'value': 'jazz'},
      ],
      lastEventId: 'cursor-1',
    );

    final uri = sseClient.lastUri;
    expect(uri, isNotNull);
    expect(uri!.path, '/api/v1/events/stream');
    expect(uri.queryParameters['past_only'], '1');
    expect(uri.queryParameters['confirmed_only'], '1');
    expect(uri.queryParametersAll['categories[]'], ['music']);
    expect(uri.queryParametersAll['tags[]'], ['live']);
    expect(uri.queryParameters['taxonomy[0][type]'], 'genre');
    expect(uri.queryParameters['taxonomy[0][value]'], 'jazz');
    expect(sseClient.lastEventId, 'cursor-1');
    expect(sseClient.lastHeaders?['Authorization'], 'Bearer test-token');
  });

  test('watchEventsStream forwards search and omits geo params when searching',
      () {
    final sseClient = _RecordingSseClient();
    final backend = LaravelScheduleBackend(
      dio: Dio()..httpClientAdapter = _NoopAdapter(),
      sseClient: sseClient,
    );

    backend.watchEventsStream(
      searchQuery: 'Sola',
      originLat: -20.0,
      originLng: -40.0,
      maxDistanceMeters: 5000,
    );

    final uri = sseClient.lastUri;
    expect(uri, isNotNull);
    expect(uri!.queryParameters['search'], 'Sola');
    expect(uri.queryParameters.containsKey('origin_lat'), isFalse);
    expect(uri.queryParameters.containsKey('origin_lng'), isFalse);
    expect(uri.queryParameters.containsKey('max_distance_meters'), isFalse);
  });

  test('fetchEventsPage forwards search and omits geo params when searching',
      () async {
    final adapter = _NoopAdapter(
      responseData: const {
        'data': {
          'items': [],
          'has_more': false,
        },
      },
    );
    final backend = LaravelScheduleBackend(
      dio: Dio()..httpClientAdapter = adapter,
      sseClient: _RecordingSseClient(),
    );

    await backend.fetchEventsPage(
      page: 1,
      pageSize: 10,
      showPastOnly: false,
      searchQuery: 'Sola',
      originLat: -20.0,
      originLng: -40.0,
      maxDistanceMeters: 5000,
    );

    final options = adapter.lastOptions;
    expect(options, isNotNull);
    final params = options!.queryParameters;
    expect(params['search'], 'Sola');
    expect(params.containsKey('origin_lat'), isFalse);
    expect(params.containsKey('origin_lng'), isFalse);
    expect(params.containsKey('max_distance_meters'), isFalse);
  });

  test('fetchEventsPage bootstraps auth when token is empty', () async {
    final authRepository = GetIt.I.get<AuthRepositoryContract<UserContract>>()
        as _FakeAuthRepository;
    authRepository.setUserToken(authRepoString(''));

    final adapter = _NoopAdapter(
      responseData: const {
        'data': {
          'items': [],
          'has_more': false,
        },
      },
    );
    final backend = LaravelScheduleBackend(
      dio: Dio()..httpClientAdapter = adapter,
      sseClient: _RecordingSseClient(),
    );

    await backend.fetchEventsPage(
      page: 1,
      pageSize: 10,
      showPastOnly: false,
    );

    expect(authRepository.initCallCount, 1);
    final headers = adapter.lastOptions?.headers ?? const <String, dynamic>{};
    expect(headers['Authorization'], 'Bearer refreshed-token');
  });
}

class _RecordingSseClient implements SseClient {
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  String? lastEventId;

  @override
  Stream<SseMessage> connect(
    Uri uri, {
    Map<String, String>? headers,
    String? lastEventId,
  }) {
    lastUri = uri;
    lastHeaders = headers;
    this.lastEventId = lastEventId;
    return const Stream<SseMessage>.empty();
  }
}

class _NoopAdapter implements HttpClientAdapter {
  _NoopAdapter({
    this.responseData = const <String, Object?>{},
  });

  final Map<String, Object?> responseData;
  RequestOptions? lastOptions;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return ResponseBody.fromString(
      jsonEncode(responseData),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
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
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(AuthRepositoryContractParamString newPassword,
      AuthRepositoryContractParamString confirmPassword) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> updateUser(
      UserCustomData data) async {}
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
  return buildAppDataFromInitialization(
      remoteData: remoteData, localInfo: localInfo);
}

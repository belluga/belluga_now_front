import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/proximity_preferences_backend/laravel_proximity_preferences_backend.dart';
import 'package:belluga_now/infrastructure/dal/dto/proximity_preference_dto.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
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
      'fetch revalidates persisted token before tenant-public proximity requests',
      () async {
    final authRepository = GetIt.I.get<AuthRepositoryContract<UserContract>>()
        as _FakeAuthRepository;
    authRepository.setUserToken(authRepoString('stale-token'));
    authRepository.tokenAfterInit = 'refreshed-token';
    authRepository.refreshTokenOnInit = true;

    final adapter = _RecordingAdapter(
      response: const {
        'data': {
          'max_distance_meters': 5000,
          'location_preference': {
            'mode': 'live_device_location',
          },
        },
      },
    );
    final backend = LaravelProximityPreferencesBackend(
      dio: Dio()..httpClientAdapter = adapter,
    );

    final result = await backend.fetch();

    expect(result, isA<ProximityPreferenceDTO>());
    expect(authRepository.ensureTenantPublicIdentityReadyCallCount, 1);
    expect(authRepository.initCallCount, 0);
    expect(
      adapter.lastRequest?.headers['Authorization'],
      'Bearer refreshed-token',
    );
    expect(
      adapter.lastRequest?.uri.path,
      '/api/v1/profile/proximity-preferences',
    );
  });

  test(
      'upsert revalidates persisted token before tenant-public proximity writes',
      () async {
    final authRepository = GetIt.I.get<AuthRepositoryContract<UserContract>>()
        as _FakeAuthRepository;
    authRepository.setUserToken(authRepoString('stale-token'));
    authRepository.tokenAfterInit = 'refreshed-token';
    authRepository.refreshTokenOnInit = true;

    final adapter = _RecordingAdapter(
      response: const {
        'data': {
          'max_distance_meters': 5000,
          'location_preference': {
            'mode': 'live_device_location',
          },
        },
      },
    );
    final backend = LaravelProximityPreferencesBackend(
      dio: Dio()..httpClientAdapter = adapter,
    );

    await backend.upsert(
      ProximityPreferenceDTO(
        maxDistanceMeters: 5000,
        mode: 'live_device_location',
      ),
    );

    expect(authRepository.ensureTenantPublicIdentityReadyCallCount, 1);
    expect(authRepository.initCallCount, 0);
    expect(
      adapter.lastRequest?.headers['Authorization'],
      'Bearer refreshed-token',
    );
    expect(
      adapter.lastRequest?.uri.path,
      '/api/v1/profile/proximity-preferences',
    );
  });

  test('fetch fails closed when auth repository is missing', () async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());

    final adapter = _RecordingAdapter(
      response: const {
        'data': {
          'max_distance_meters': 5000,
          'location_preference': {
            'mode': 'live_device_location',
          },
        },
      },
    );
    final backend = LaravelProximityPreferencesBackend(
      dio: Dio()..httpClientAdapter = adapter,
    );

    await expectLater(
      () => backend.fetch(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('require a registered AuthRepositoryContract'),
        ),
      ),
    );
    expect(adapter.lastRequest, isNull);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({
    required this.response,
  });

  final Map<String, Object?> response;
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
      jsonEncode(response),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  String _token = 'test-token';
  String tokenAfterInit = 'refreshed-token';
  int initCallCount = 0;
  int ensureTenantPublicIdentityReadyCallCount = 0;
  bool refreshTokenOnInit = false;

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
    if (refreshTokenOnInit || _token.trim().isEmpty) {
      _token = tokenAfterInit;
    }
  }

  @override
  Future<void> ensureTenantPublicIdentityReady() async {
    ensureTenantPublicIdentityReadyCallCount += 1;
    if (refreshTokenOnInit || _token.trim().isEmpty) {
      _token = tokenAfterInit;
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

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://guarappari.belluga.space',
    'profile_types': const [],
    'domains': ['https://guarappari.belluga.space'],
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
    'hostname': 'guarappari.belluga.space',
    'href': 'https://guarappari.belluga.space',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

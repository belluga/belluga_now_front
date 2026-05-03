import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/user_events_backend/laravel_user_events_backend.dart';
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
      'fetchConfirmedOccurrenceIds bootstraps auth token when initially missing',
      () async {
    final authRepository = GetIt.I.get<AuthRepositoryContract<UserContract>>()
        as _FakeAuthRepository;
    authRepository.setUserToken(authRepoString(''));
    authRepository.tokenAfterInit = 'refreshed-token';

    final adapter = _RecordingAdapter(
      response: const {
        'data': {
          'confirmed_occurrence_ids': ['occurrence-1'],
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelUserEventsBackend(dio: dio);

    final response = await backend.fetchConfirmedOccurrenceIds();

    expect(authRepository.initCallCount, 1);
    expect(response['confirmed_occurrence_ids'], ['occurrence-1']);
    expect(
      adapter.lastRequest?.headers['Authorization'],
      'Bearer refreshed-token',
    );
    expect(
        adapter.lastRequest?.uri.path, '/api/v1/events/attendance/confirmed');
  });
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  String _token = 'test-token';
  String? tokenAfterInit;
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
    if (_token.trim().isEmpty &&
        tokenAfterInit != null &&
        tokenAfterInit!.trim().isNotEmpty) {
      _token = tokenAfterInit!;
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
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

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

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
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
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
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
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

import 'dart:convert';

import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/discovery_filters/laravel_discovery_filters_http_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract>(_FakeAuthRepository());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('getCatalog sends authenticated request to surface endpoint', () async {
    final adapter = _DiscoveryFiltersAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LaravelDiscoveryFiltersHttpService(
      context: BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://tenant.test/admin/api',
      ),
      dio: dio,
    );

    final dto = await service.getCatalog('public_map.primary');

    final request = adapter.requests.single;
    expect(request.path, '/v1/discovery-filters/public_map.primary');
    expect(request.headers['Accept'], 'application/json');
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(dto.toDomain().filters.single.key, 'events');
  });
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  @override
  Object get backend => Object();

  @override
  String get userToken => 'test-token';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

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

class _DiscoveryFiltersAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(
        <String, Object?>{
          'surface': 'public_map.primary',
          'filters': <Object?>[
            <String, Object?>{
              'key': 'events',
              'label': 'Eventos',
              'target': 'map_poi',
              'query': <String, Object?>{
                'entities': <String>['event'],
              },
            },
          ],
          'type_options': const <String, Object?>{},
        },
      ),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}

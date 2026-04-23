import 'dart:convert';

import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/map/laravel_map_poi_http_service.dart';
import 'package:belluga_now/infrastructure/repositories/city_map_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract>(_FakeAuthRepository());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
      'fetchFilters keeps map primary filters limited to configured categories',
      () async {
    final adapter = _MapFiltersAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = CityMapRepository(
      laravelHttpService: LaravelMapPoiHttpService(
        context: BackendContext(
          baseUrl: 'https://tenant.test/api',
          adminUrl: 'https://tenant.test/admin/api',
        ),
        dio: dio,
      ),
    );

    final filters = await repository.fetchFilters();

    expect(filters.categories, hasLength(1));
    expect(
      filters.categories.map((category) => category.label),
      isNot(contains('brasilidades')),
    );
    expect(
      filters.categories.map((category) => category.key),
      isNot(contains('taxonomy:genre:brasilidades')),
    );
    expect(filters.categories.single.key, 'events');
    expect(filters.categories.single.serverQuery?.sourceValue?.value, 'event');
  });
}

class _MapFiltersAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

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
      jsonEncode({
        'categories': [
          {
            'key': 'events',
            'label': 'Events',
            'count': 1,
            'override_marker': false,
            'query': {'source': 'event'},
          },
        ],
        'tags': const <Object>[],
        'taxonomy_terms': [
          {
            'type': 'genre',
            'value': 'brasilidades',
            'name': 'Brasilidades',
            'taxonomy_name': 'Gênero Musical',
            'label': 'Brasilidades',
            'count': 1,
          },
        ],
      }),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
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

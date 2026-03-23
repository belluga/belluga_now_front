import 'dart:convert';

import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/map/laravel_map_poi_http_service.dart';
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
      'getPois sends authenticated array query params with Laravel-compatible encoding',
      () async {
    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LaravelMapPoiHttpService(
      context: BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://tenant.test/admin/api',
      ),
      dio: dio,
    );

    await service.getPois(
      PoiQuery(
        source: 'static_asset',
        categoryKeys: <String>{'beach'},
        types: <String>{'beach_spot'},
        tags: <String>{'family'},
        taxonomy: <String>{'cuisine:italian'},
      ),
    );

    final request = adapter.requests.single;
    expect(request.path, '/v1/map/pois');
    expect(request.headers['Accept'], 'application/json');
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(
      request.uri.toString(),
      contains('categories%5B%5D=beach'),
    );
    expect(
      request.uri.toString(),
      contains('types%5B%5D=beach_spot'),
    );
    expect(
      request.uri.toString(),
      contains('tags%5B%5D=family'),
    );
    expect(
      request.uri.toString(),
      contains('taxonomy%5B%5D=cuisine%3Aitalian'),
    );
  });

  test(
      'getFilters keeps server-query arrays compatible with Laravel validation',
      () async {
    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LaravelMapPoiHttpService(
      context: BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://tenant.test/admin/api',
      ),
      dio: dio,
    );

    await service.getFilters(
      PoiQuery(
        source: 'event',
        types: <String>{'showcase'},
      ),
    );

    final request = adapter.requests.single;
    expect(request.path, '/v1/map/filters');
    expect(request.headers['Accept'], 'application/json');
    expect(request.headers['Authorization'], 'Bearer test-token');
    expect(
      request.uri.toString(),
      contains('types%5B%5D=showcase'),
    );
  });

  test('getPois bootstraps auth token when initially missing', () async {
    final authRepository =
        GetIt.I.get<AuthRepositoryContract>() as _FakeAuthRepository;
    authRepository.setUserToken('');
    authRepository.tokenAfterInit = 'refreshed-token';

    final adapter = _RecordingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final service = LaravelMapPoiHttpService(
      context: BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://tenant.test/admin/api',
      ),
      dio: dio,
    );

    await service.getPois(PoiQuery());

    final request = adapter.requests.single;
    expect(authRepository.initCallCount, 1);
    expect(request.headers['Authorization'], 'Bearer refreshed-token');
  });
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  String _token = 'test-token';
  String? tokenAfterInit;
  int initCallCount = 0;

  @override
  Object get backend => Object();

  @override
  String get userToken => _token;

  @override
  void setUserToken(String? token) {
    _token = token ?? '';
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

class _RecordingAdapter implements HttpClientAdapter {
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
    final body = switch (options.path) {
      '/v1/map/filters' => <String, dynamic>{
          'categories': const <Object>[],
          'tags': const <Object>[],
          'taxonomy_terms': const <Object>[],
        },
      _ => <String, dynamic>{
          'stacks': const <Object>[],
        },
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }
}

import 'dart:convert';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    FlutterSecureStorage.setMockInitialValues({});
    GetIt.I.registerSingleton<BackendContext>(
      BackendContext(
        baseUrl: 'https://tenant.test/api',
        adminUrl: 'https://admin.test/admin/api',
      ),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('login stores token and validates session', () async {
    final dio = Dio(
      BaseOptions(baseUrl: 'https://admin.test/admin/api'),
    );
    final adapter = QueueHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    final repository = LandlordAuthRepository(dio: dio);
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(repository);

    adapter.enqueuePost(
      path: '/v1/auth/login',
      response: {
        'data': {
          'token': 'landlord-token',
          'user': {'id': '507f1f77bcf86cd799439011'},
        },
      },
    );
    adapter.enqueueGet(path: '/v1/auth/token_validate', response: {'data': {}});
    adapter.enqueueGet(
      path: '/v1/me',
      response: {'data': {'user_id': '507f1f77bcf86cd799439011'}},
    );

    await repository.loginWithEmailPassword('admin@test.com', 'Secret!234');

    final storedToken =
        await LandlordAuthRepository.storage.read(key: 'landlord_token');
    final storedUserId =
        await LandlordAuthRepository.storage.read(key: 'landlord_user_id');
    expect(storedToken, 'landlord-token');
    expect(storedUserId, '507f1f77bcf86cd799439011');
    expect(repository.hasValidSession, isTrue);
  });

  test('init clears session on validation failure', () async {
    FlutterSecureStorage.setMockInitialValues({
      'landlord_token': 'stale-token',
      'landlord_user_id': '507f1f77bcf86cd799439012',
    });
    final dio = Dio(
      BaseOptions(baseUrl: 'https://admin.test/admin/api'),
    );
    final adapter = QueueHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    final repository = LandlordAuthRepository(dio: dio);

    adapter.enqueueGet(
      path: '/v1/auth/token_validate',
      throwError: true,
    );

    await repository.init();

    final storedToken =
        await LandlordAuthRepository.storage.read(key: 'landlord_token');
    final storedUserId =
        await LandlordAuthRepository.storage.read(key: 'landlord_user_id');
    expect(storedToken, isNull);
    expect(storedUserId, isNull);
    expect(repository.hasValidSession, isFalse);
  });
}

class QueueHttpClientAdapter implements HttpClientAdapter {
  final List<_RequestStub> _stubs = <_RequestStub>[];

  void enqueuePost({
    required String path,
    required Map<String, dynamic> response,
  }) =>
      _stubs.add(_RequestStub('post', path, response: response));

  void enqueueGet({
    required String path,
    Map<String, dynamic>? response,
    bool throwError = false,
  }) =>
      _stubs.add(
        _RequestStub(
          'get',
          path,
          response: response ?? const {},
          throwError: throwError,
        ),
      );

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final stub = _stubs.removeAt(0);
    if (stub.throwError) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unauthorized'}),
        401,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(stub.response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RequestStub {
  _RequestStub(
    this.method,
    this.path, {
    required this.response,
    this.throwError = false,
  });

  final String method;
  final String path;
  final Map<String, dynamic> response;
  final bool throwError;
}

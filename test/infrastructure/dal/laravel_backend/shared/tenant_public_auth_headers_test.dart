import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  late _FakeAuthRepository authRepository;

  setUp(() async {
    await GetIt.I.reset();
    authRepository = _FakeAuthRepository();
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
    'retryOnceOnUnauthorized recovers the anonymous token and retries once',
    () async {
      var attempts = 0;

      final result =
          await TenantPublicAuthHeaders.retryOnceOnUnauthorized<String>(
            includeJsonAccept: true,
            action: (headers) async {
              attempts += 1;
              if (attempts == 1) {
                expect(headers['Authorization'], 'Bearer token-1');
                throw DioException(
                  requestOptions: RequestOptions(path: '/api/v1/agenda'),
                  response: Response(
                    requestOptions: RequestOptions(path: '/api/v1/agenda'),
                    statusCode: 401,
                  ),
                );
              }

              expect(headers['Authorization'], 'Bearer token-2');
              expect(headers['Accept'], 'application/json');
              return 'ok';
            },
          );

      expect(result, 'ok');
      expect(attempts, 2);
      expect(authRepository.ensureReadyCalls, 1);
      expect(authRepository.recoverCalls, 1);
    },
  );

  test(
    'retryOnceOnUnauthorized does not recover for non-401 failures',
    () async {
      await expectLater(
        TenantPublicAuthHeaders.retryOnceOnUnauthorized<void>(
          action: (_) async {
            throw DioException(
              requestOptions: RequestOptions(path: '/api/v1/agenda'),
              response: Response(
                requestOptions: RequestOptions(path: '/api/v1/agenda'),
                statusCode: 403,
              ),
            );
          },
        ),
        throwsA(isA<DioException>()),
      );

      expect(authRepository.recoverCalls, 0);
    },
  );
}

class _FakeAuthRepository extends AuthRepositoryContract {
  String _userToken = 'token-1';
  int ensureReadyCalls = 0;
  int recoverCalls = 0;

  @override
  Object get backend => Object();

  @override
  bool get isAuthorized => false;

  @override
  bool get isUserLoggedIn => false;

  @override
  String get userToken => _userToken;

  @override
  Future<void> ensureTenantPublicIdentityReady() async {
    ensureReadyCalls += 1;
  }

  @override
  Future<void>
  recoverTenantPublicIdentityAfterUnauthorizedPublicRequest() async {
    recoverCalls += 1;
    _userToken = 'token-2';
  }

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> createNewPassword(newPassword, confirmPassword) async {}

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(email, password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(email) async {}

  @override
  Future<void> sendTokenRecoveryPassword(email, codigoEnviado) async {}

  @override
  void setUserToken(token) {
    _userToken = token?.value ?? '';
  }

  @override
  Future<void> signUpWithEmailPassword(name, email, password) async {}

  @override
  Future<void> updateUser(data) async {}
}

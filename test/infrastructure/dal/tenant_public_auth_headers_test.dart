import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/shared/tenant_public_auth_headers.dart';
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

  test('resolveToken fails closed when auth repository is missing', () async {
    await expectLater(
      () => TenantPublicAuthHeaders.resolveToken(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('require a registered AuthRepositoryContract'),
        ),
      ),
    );
  });

  test('resolveToken propagates readiness failures', () async {
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _ThrowingAuthRepository(),
    );

    await expectLater(
      () => TenantPublicAuthHeaders.resolveToken(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('forced readiness failure'),
        ),
      ),
    );
  });

  test('resolveToken fails closed when readiness leaves token empty', () async {
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _EmptyTokenAuthRepository(),
    );

    await expectLater(
      () => TenantPublicAuthHeaders.resolveToken(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('require a resolved bearer token'),
        ),
      ),
    );
  });
}

class _EmptyTokenAuthRepository extends AuthRepositoryContract<UserContract> {
  @override
  BackendContract get backend => throw UnimplementedError();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> ensureTenantPublicIdentityReady() async {}

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

class _ThrowingAuthRepository extends _EmptyTokenAuthRepository {
  @override
  Future<void> ensureTenantPublicIdentityReady() async {
    throw StateError('forced readiness failure');
  }
}

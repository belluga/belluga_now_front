import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/modular_app/modules/invites_module.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('invite routes keep anonymous entry and auth-protected share flow', () {
    final module = InvitesModule();
    final routes = module.routes;

    final flowRoute = routes.firstWhere((route) => route.path == '/convites');
    final inviteAliasRoute =
        routes.firstWhere((route) => route.path == '/invite');
    final shareRoute =
        routes.firstWhere((route) => route.path == '/convites/compartilhar');

    expect(
      flowRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard],
    );
    expect(
      inviteAliasRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard],
    );
    expect(
      shareRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard, AuthRouteGuard],
    );
  });

  test('/invite is no longer implemented via RedirectRoute', () {
    final module = InvitesModule();
    final inviteRoute =
        module.routes.firstWhere((route) => route.path == '/invite');

    expect(inviteRoute, isNot(isA<RedirectRoute>()));
  });
}

class _FakeAuthRepository extends AuthRepositoryContract {
  @override
  Object get backend => Object();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => null;

  @override
  Future<void> init() async {}

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

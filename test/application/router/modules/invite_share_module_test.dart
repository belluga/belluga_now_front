import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/modular_app/modules/invite_share_module.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/inviteables_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<InvitesRepositoryContract>(
      _FakeInvitesRepository(),
    );
    GetIt.I.registerSingleton<ContactsRepositoryContract>(
      _FakeContactsRepository(),
    );
    GetIt.I.registerSingleton<InviteablesRepositoryContract>(
      _FakeInviteablesRepository(),
    );
    GetIt.I.registerSingleton<AppData>(_FakeAppData());
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('owns the invite share route behind tenant and auth guards', () {
    final module = InviteShareModule();
    final routes = module.routes;

    expect(routes, hasLength(1));

    final route = routes.single;
    expect(route.path, '/convites/compartilhar');
    expect(route, isNot(isA<RedirectRoute>()));
    expect(
      route.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard, AuthRouteGuard],
    );
  });

  test('registers and disposes the invite share controller via module scope',
      () async {
    final module = InviteShareModule();

    await module.init();

    expect(
      GetIt.I.isRegistered<InviteShareScreenController>(),
      isTrue,
    );
    final controller = GetIt.I.get<InviteShareScreenController>();

    await module.dispose();

    expect(
      GetIt.I.isRegistered<InviteShareScreenController>(),
      isFalse,
    );
    expect(
      () => controller.sendingInviteRecipientKeysStreamValue.addValue(
        const <String>{},
      ),
      throwsStateError,
    );
  });
}

class _FakeInvitesRepository extends Fake
    implements InvitesRepositoryContract {}

class _FakeInviteablesRepository extends Fake
    implements InviteablesRepositoryContract {}

class _FakeContactsRepository extends Fake
    implements ContactsRepositoryContract {}

class _FakeAppData extends Fake implements AppData {}

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

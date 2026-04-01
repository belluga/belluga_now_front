import 'package:belluga_now/application/router/guards/any_location_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/guards/web_anonymous_fallback_guard.dart';
import 'package:belluga_now/application/router/guards/web_anonymous_promotion_guard.dart';
import 'package:belluga_now/application/router/modular_app/modules/app_promotion_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_module.dart';
import 'package:belluga_now/application/router/modular_app/modules/schedule_module.dart';
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

  test('auth routes are tenant-scoped and promotion-gated on anonymous web', () {
    final routes = AuthModule().routes;
    final loginRoute = routes.firstWhere((route) => route.path == '/auth/login');
    final recoveryRoute =
        routes.firstWhere((route) => route.path == '/auth/recover_password');

    expect(
      loginRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard, WebAnonymousPromotionGuard],
    );
    expect(
      recoveryRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard, WebAnonymousPromotionGuard],
    );
  });

  test('discovery public routes remain tenant-scoped', () {
    final routes = DiscoveryModule().routes;

    for (final path in <String>['/descobrir', '/parceiro/:slug']) {
      final route = routes.firstWhere((candidate) => candidate.path == path);
      expect(
        route.guards.map((guard) => guard.runtimeType).toList(),
        [TenantRouteGuard],
      );
    }
  });

  test('schedule routes keep agenda blocked and event detail public', () {
    final routes = ScheduleModule().routes;
    final agendaRoute = routes.firstWhere((route) => route.path == '/agenda');
    final eventDetailRoute =
        routes.firstWhere((route) => route.path == '/agenda/evento/:slug');

    expect(
      agendaRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard, WebAnonymousFallbackGuard],
    );
    expect(
      eventDetailRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard],
    );
  });

  test('map public routes remain tenant-scoped and location-gated', () {
    final routes = MapModule().routes;

    for (final path in <String>['/mapa', '/mapa/poi']) {
      final route = routes.firstWhere((candidate) => candidate.path == path);
      expect(
        route.guards.map((guard) => guard.runtimeType).toList(),
        [TenantRouteGuard, AnyLocationRouteGuard],
      );
    }
  });

  test('initialization and promotion public routes remain tenant-scoped', () {
    final locationRoute = InitializationModule()
        .routes
        .firstWhere((route) => route.path == '/location/permission');
    final promotionRoute = AppPromotionModule()
        .routes
        .firstWhere((route) => route.path == '/baixe-o-app');

    expect(
      locationRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard],
    );
    expect(
      promotionRoute.guards.map((guard) => guard.runtimeType).toList(),
      [TenantRouteGuard],
    );
  });
}

class _FakeAuthRepository extends AuthRepositoryContract {
  @override
  Object get backend => Object();

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  String get userToken => '';

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

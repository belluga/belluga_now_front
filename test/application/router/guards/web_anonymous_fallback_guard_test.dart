import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/web_anonymous_fallback_guard.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('allows anonymous app runtime navigation without fallback', () {
    final guard = WebAnonymousFallbackGuard(
      isWebRuntime: false,
      authRepository: _FakeAuthRepository(authorized: false),
    );
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(fullPath: '/agenda'),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [true]);
    expect(router.replacedWithHome, isFalse);
  });

  test('redirects anonymous web navigation to home fallback when blocked', () {
    final guard = WebAnonymousFallbackGuard(
      isWebRuntime: true,
      authRepository: _FakeAuthRepository(authorized: false),
    );
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(fullPath: '/agenda'),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [false]);
    expect(router.replacedWithHome, isTrue);
  });

  test('allows anonymous web invite preview when allowance approves route', () {
    final guard = WebAnonymousFallbackGuard(
      isWebRuntime: true,
      authRepository: _FakeAuthRepository(authorized: false),
      allowAnonymousWeb: (route) =>
          route.queryParams.rawMap['code']?.toString().trim().isNotEmpty ??
          false,
    );
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(
        fullPath: '/invite',
        queryParams: const {'code': 'ABC123'},
      ),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [true]);
    expect(router.replacedWithHome, isFalse);
  });
}

class _RecordingNavigationResolver extends NavigationResolver {
  _RecordingNavigationResolver({
    required RouteMatch route,
  }) : super(
          _RecordingStackRouter(),
          Completer<ResolverResult>(),
          route,
        );

  final List<bool> nextCalls = <bool>[];

  @override
  void next([bool continueNavigation = true]) {
    nextCalls.add(continueNavigation);
  }
}

class _RecordingStackRouter extends Mock implements StackRouter {
  bool replacedWithHome = false;

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replacedWithHome =
        routes.length == 1 && routes.single.routeName == 'TenantHomeRoute';
  }
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.fullPath,
    Map<String, dynamic> queryParams = const {},
  }) : _queryParams = Parameters(queryParams);

  @override
  final String fullPath;

  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;
}

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({required this.authorized});

  final bool authorized;

  @override
  Object get backend => Object();

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  String get userToken => authorized ? 'token' : '';

  @override
  bool get isUserLoggedIn => authorized;

  @override
  bool get isAuthorized => authorized;

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => authorized ? 'user-id' : null;

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

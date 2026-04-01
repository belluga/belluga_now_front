import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/web_anonymous_promotion_guard.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows anonymous app runtime navigation without promotion redirect', () {
    final guard = WebAnonymousPromotionGuard(
      isWebRuntime: false,
      authRepository: _FakeAuthRepository(authorized: false),
    );
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(fullPath: '/auth/login'),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [true]);
    expect(resolver.redirectedRoute, isNull);
  });

  test('redirects anonymous web navigation to promotion preserving redirect', () {
    final guard = WebAnonymousPromotionGuard(
      isWebRuntime: true,
      authRepository: _FakeAuthRepository(authorized: false),
    );
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(
        fullPath: '/auth/login',
        queryParams: const {'redirect': '/profile'},
      ),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [false]);
    expect(resolver.redirectedRoute, isA<AppPromotionRoute>());
    expect(
      resolver.redirectedRoute!.rawQueryParams['redirect'],
      '/auth/login?redirect=%2Fprofile',
    );
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
  PageRouteInfo? redirectedRoute;

  @override
  void next([bool continueNavigation = true]) {
    nextCalls.add(continueNavigation);
  }

  @override
  void redirectUntil(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool replace = false,
  }) {
    redirectedRoute = route;
  }
}

class _RecordingStackRouter extends Fake implements StackRouter {}

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

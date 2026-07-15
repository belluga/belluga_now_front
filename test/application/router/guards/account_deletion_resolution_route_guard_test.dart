import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/account_deletion_resolution_route_guard.dart';
import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('allows the internal resolution route only for confirmed deletion', () {
    final authRepository = _FakeAuthRepository()
      ..setJourney(AccountDeletionJourneyPhase.confirmed);
    final resolver = _RecordingNavigationResolver();
    final guard = AccountDeletionResolutionRouteGuard(
      authRepository: authRepository,
    );

    guard.onNavigation(resolver, _RecordingStackRouter());

    expect(resolver.nextCalls, [true]);
    expect(resolver.redirectedRoute, isNull);
  });

  test('allows the internal resolution route for unknown deletion outcome', () {
    final authRepository = _FakeAuthRepository()
      ..setJourney(AccountDeletionJourneyPhase.unknown);
    final resolver = _RecordingNavigationResolver();
    final guard = AccountDeletionResolutionRouteGuard(
      authRepository: authRepository,
    );

    guard.onNavigation(resolver, _RecordingStackRouter());

    expect(resolver.nextCalls, [true]);
    expect(resolver.redirectedRoute, isNull);
  });

  test('rejects cold or direct resolution-route entry', () {
    final resolver = _RecordingNavigationResolver();
    final guard = AccountDeletionResolutionRouteGuard(
      authRepository: _FakeAuthRepository(),
    );

    guard.onNavigation(resolver, _RecordingStackRouter());

    expect(resolver.nextCalls, [false]);
    expect(resolver.redirectedRoute?.routeName, TenantHomeRoute.name);
  });
}

class _FakeAuthRepository extends AuthRepositoryContract {
  @override
  Object get backend => Object();

  void setJourney(AccountDeletionJourneyPhase phase) {
    accountDeletionJourneyStreamValue.addValue(
      AccountDeletionJourneyState(phase),
    );
  }

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

class _RecordingNavigationResolver extends NavigationResolver {
  _RecordingNavigationResolver()
    : super(
        _RecordingStackRouter(),
        Completer<ResolverResult>(),
        _FakeRouteMatch(),
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

class _RecordingStackRouter extends Mock implements StackRouter {}

class _FakeRouteMatch extends Fake implements RouteMatch {}

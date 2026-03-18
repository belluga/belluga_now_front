import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('allows navigation when user is authorized', () {
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(authorized: true),
    );

    final guard = AuthRouteGuard();
    final resolver = _MockNavigationResolver();
    final router = _RecordingStackRouter();
    resolver.routeValue = _FakeRouteMatch(fullPath: '/convites');

    guard.onNavigation(resolver, router);

    verify(resolver.next(true)).called(1);
    verifyNever(resolver.next(false));
    expect(router.lastPushedPath, isNull);
  });

  test('redirects unauthorized user preserving deep-link query params', () {
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(authorized: false),
    );

    final guard = AuthRouteGuard();
    final resolver = _MockNavigationResolver();
    final router = _RecordingStackRouter();
    resolver.routeValue = _FakeRouteMatch(
      fullPath: '/convites',
      queryParams: const {'code': '31F8RN5QJ9'},
    );

    guard.onNavigation(resolver, router);

    verify(resolver.next(false)).called(1);
    expect(
      router.lastPushedPath,
      '/auth/login?redirect=%2Fconvites%3Fcode%3D31F8RN5QJ9',
    );
  });

  test('normalizes path when route fullPath does not include leading slash',
      () {
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(authorized: false),
    );

    final guard = AuthRouteGuard();
    final resolver = _MockNavigationResolver();
    final router = _RecordingStackRouter();
    resolver.routeValue = _FakeRouteMatch(
      fullPath: 'convites',
      queryParams: const {'code': 'ABC123'},
    );

    guard.onNavigation(resolver, router);

    verify(resolver.next(false)).called(1);
    expect(
      router.lastPushedPath,
      '/auth/login?redirect=%2Fconvites%3Fcode%3DABC123',
    );
  });
}

class _MockNavigationResolver extends Mock implements NavigationResolver {
  RouteMatch _route = _FakeRouteMatch(fullPath: '/');

  set routeValue(RouteMatch value) {
    _route = value;
  }

  @override
  RouteMatch get route => _route;
}

class _RecordingStackRouter extends Mock implements StackRouter {
  String? lastPushedPath;

  @override
  Future<T?> pushPath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    lastPushedPath = path;
    return null;
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
  void setUserToken(String? token) {}

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

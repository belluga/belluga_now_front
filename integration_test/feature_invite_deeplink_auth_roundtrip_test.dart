import 'dart:developer' as developer;

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/widgets/auth_login_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  developer.postEvent(
    'integration_test.VmServiceProxyGoldenFileComparator',
    const {},
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  testWidgets('login flow returns to deep link with code preserved',
      (tester) async {
    final router = _RecordingStackRouter(canPopValue: false);
    final routeData = _buildRouteData(
      router,
      queryParams: {
        'redirect': Uri.encodeComponent('/invite?code=31F8RN5QJ9'),
      },
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: AuthLoginEffects(
              generalError: null,
              loginResult: true,
              signUpResult: null,
              onClearGeneralError: () {},
              onClearLoginResult: () {},
              onClearSignUpResult: () {},
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(router.lastReplacedPath, '/invite?code=31F8RN5QJ9');
  });

  testWidgets('signup flow also returns to deep link with code preserved',
      (tester) async {
    final router = _RecordingStackRouter(canPopValue: true);
    final routeData = _buildRouteData(
      router,
      queryParams: {
        'redirect': Uri.encodeComponent('/invite?code=31F8RN5QJ9'),
      },
    );

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: RouteDataScope(
            routeData: routeData,
            child: AuthLoginEffects(
              generalError: null,
              loginResult: null,
              signUpResult: true,
              onClearGeneralError: () {},
              onClearLoginResult: () {},
              onClearSignUpResult: () {},
              child: const Scaffold(body: SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(router.popCalled, isTrue);
    expect(router.lastReplacedPath, '/invite?code=31F8RN5QJ9');
  });
}

class _RecordingStackRouter extends Mock implements RootStackRouter {
  _RecordingStackRouter({required this.canPopValue});

  final bool canPopValue;
  String? lastReplacedPath;
  bool popCalled = false;

  @override
  RootStackRouter get root => this;

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return canPopValue;
  }

  @override
  Future<T?> replacePath<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    lastReplacedPath = path;
    return null;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCalled = true;
  }
}

RouteData _buildRouteData(
  StackRouter router, {
  required Map<String, dynamic> queryParams,
}) {
  final match = RouteMatch(
    config: AutoRoute(page: AuthLoginRoute.page, path: '/auth/login'),
    segments: const ['auth', 'login'],
    stringMatch: '/auth/login',
    key: const ValueKey('auth-login'),
    queryParams: Parameters(queryParams),
  );
  return RouteData(
    route: match,
    router: router,
    stackKey: const ValueKey('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );
}

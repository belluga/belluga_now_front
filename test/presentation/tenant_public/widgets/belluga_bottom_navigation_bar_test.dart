import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  testWidgets('pushes map as a forward AutoRoute stack transition',
      (tester) async {
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: const BellugaBottomNavigationBar(currentIndex: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    expect(router.pushCalls, 1);
    expect(router.lastPushedRoute?.routeName, CityMapRoute.name);
  });

  testWidgets('pushes profile as a forward AutoRoute stack transition',
      (tester) async {
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: const BellugaBottomNavigationBar(currentIndex: 0),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(router.pushCalls, 1);
    expect(router.lastPushedRoute?.routeName, ProfileRoute.name);
  });

  testWidgets('returns to home through AutoRoute navigate semantics',
      (tester) async {
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: const BellugaBottomNavigationBar(currentIndex: 1),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    expect(router.navigateCalls, 1);
    expect(router.lastNavigatedRoute?.routeName, TenantHomeRoute.name);
    expect(router.pushCalls, 0);
  });

  testWidgets('tapping the current destination is a no-op', (tester) async {
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildWidget(
        router: router,
        child: const BellugaBottomNavigationBar(currentIndex: 1),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();

    expect(router.navigateCalls, 0);
  });
}

Widget _buildWidget({
  required _RecordingStackRouter router,
  required Widget child,
}) {
  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: Scaffold(
        bottomNavigationBar: child,
      ),
    ),
  );
}

class _RecordingStackRouter extends Mock implements RootStackRouter {
  int navigateCalls = 0;
  int pushCalls = 0;
  PageRouteInfo<dynamic>? lastNavigatedRoute;
  PageRouteInfo<dynamic>? lastPushedRoute;

  @override
  RootStackRouter get root => this;

  @override
  Future<dynamic> navigate(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    navigateCalls += 1;
    lastNavigatedRoute = route;
    return null;
  }

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    pushCalls += 1;
    lastPushedRoute = route;
    return null;
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/boundary_route_dismissal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('promotion dismiss route resolves invite preview when redirect carries code',
      () {
    final route = resolveBoundaryDismissRoute(
      kind: BoundaryDismissKind.appPromotion,
      redirectPath: '/invite?code=ABC123',
      buildRouteFromPath: _buildRouteFromPath,
    );

    expect(route.routeName, InviteEntryRoute.name);
  });

  test('promotion dismiss route resolves home for auth-owned redirects', () {
    final route = resolveBoundaryDismissRoute(
      kind: BoundaryDismissKind.appPromotion,
      redirectPath: '/profile',
      buildRouteFromPath: _buildRouteFromPath,
    );

    expect(route.routeName, TenantHomeRoute.name);
  });

  test('location permission dismiss route resolves home for map redirects', () {
    final route = resolveBoundaryDismissRoute(
      kind: BoundaryDismissKind.locationPermission,
      redirectPath: '/mapa?poi=event:evt-001',
      buildRouteFromPath: _buildRouteFromPath,
    );

    expect(route.routeName, TenantHomeRoute.name);
  });

  test('location permission dismiss route remains rooted at home', () {
    final route = resolveBoundaryDismissRoute(
      kind: BoundaryDismissKind.locationPermission,
      redirectPath: '/profile?tab=settings',
      buildRouteFromPath: _buildRouteFromPath,
    );

    expect(route.routeName, TenantHomeRoute.name);
  });
}

PageRouteInfo<dynamic>? _buildRouteFromPath(String? path) {
  final uri = Uri.tryParse(path ?? '');
  if (uri == null) {
    return null;
  }

  return switch (uri.path) {
    '/' => const TenantHomeRoute(),
    '/invite' => const InviteEntryRoute(),
    '/profile' => const ProfileRoute(),
    _ => null,
  };
}

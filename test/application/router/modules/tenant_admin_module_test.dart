import 'package:belluga_now/application/router/guards/landlord_route_guard.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('/admin shell route is landlord-guarded and classified as dashboard root',
      () {
    final module = TenantAdminModule();
    final adminRoute =
        module.routes.firstWhere((route) => route.path == '/admin');

    expect(
      adminRoute.guards.map((guard) => guard.runtimeType).toList(),
      [LandlordRouteGuard],
    );
    expect(
      resolveCanonicalRouteFamilyFromMeta(adminRoute.meta),
      CanonicalRouteFamily.tenantAdminDashboard,
    );
  });
}

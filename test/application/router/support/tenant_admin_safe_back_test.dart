import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'resolveTenantAdminBackFallbackRoute uses location picker explicit fallback when provided',
      () {
    final result = resolveTenantAdminBackFallbackRoute(
      routeName: TenantAdminLocationPickerRoute.name,
      routeArgs: const TenantAdminLocationPickerRouteArgs(
        backFallbackRoute: TenantAdminSettingsLocalPreferencesRoute(),
      ),
    );

    expect(result.routeName, TenantAdminSettingsLocalPreferencesRoute.name);
  });

  test(
      'resolveTenantAdminBackFallbackRoute falls back to section root when no explicit fallback exists',
      () {
    final result = resolveTenantAdminBackFallbackRoute(
      routeName: TenantAdminLocationPickerRoute.name,
    );

    expect(result.routeName, TenantAdminAccountsListRoute.name);
  });
}

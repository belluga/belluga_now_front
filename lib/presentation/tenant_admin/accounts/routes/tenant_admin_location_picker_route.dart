import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_location_picker_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminLocationPickerRoute')
class TenantAdminLocationPickerRoutePage extends StatelessWidget {
  const TenantAdminLocationPickerRoutePage({
    super.key,
    this.initialLocation,
    this.backFallbackRoute,
  });

  final TenantAdminLocation? initialLocation;
  final PageRouteInfo<dynamic>? backFallbackRoute;

  @override
  Widget build(BuildContext context) => TenantAdminLocationPickerScreen(
        initialLocation: initialLocation,
        backFallbackRoute: backFallbackRoute,
      );
}

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/screens/tenant_admin_discovery_filter_surface_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminDiscoveryFilterSurfaceRoute')
class TenantAdminDiscoveryFilterSurfaceRoutePage extends StatelessWidget {
  const TenantAdminDiscoveryFilterSurfaceRoutePage({
    super.key,
    @QueryParam('surface') this.surfaceKey,
  });

  final String? surfaceKey;

  @override
  Widget build(BuildContext context) {
    final surface =
        TenantAdminDiscoveryFilterSurfaceDefinition.byKey(surfaceKey ?? '') ??
            TenantAdminDiscoveryFilterSurfaceDefinition.map;
    return TenantAdminDiscoveryFilterSurfaceScreen(surface: surface);
  }
}

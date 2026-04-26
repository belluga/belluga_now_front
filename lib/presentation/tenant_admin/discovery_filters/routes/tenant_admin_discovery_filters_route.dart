import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/screens/tenant_admin_discovery_filters_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminDiscoveryFiltersRoute')
class TenantAdminDiscoveryFiltersRoutePage extends StatelessWidget {
  const TenantAdminDiscoveryFiltersRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminDiscoveryFiltersScreen();
  }
}

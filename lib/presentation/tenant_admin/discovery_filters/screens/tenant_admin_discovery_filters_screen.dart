import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/models/tenant_admin_discovery_filter_surface_definition.dart';
import 'package:belluga_now/presentation/tenant_admin/discovery_filters/tenant_admin_discovery_filters_keys.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/widgets/tenant_admin_dashboard_card.dart';
import 'package:flutter/material.dart';

class TenantAdminDiscoveryFiltersScreen extends StatelessWidget {
  const TenantAdminDiscoveryFiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: TenantAdminDiscoveryFiltersKeys.listScreen,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Filtros',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure os filtros públicos que serão usados nas superfícies do tenant.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final surface in TenantAdminDiscoveryFilterSurfaceDefinition
            .adminConfigurableValues) ...[
          TenantAdminDashboardCard(
            key: TenantAdminDiscoveryFiltersKeys.surfaceCard(surface.key),
            icon: _iconForSurface(surface),
            title: surface.title,
            description: surface.description,
            onTap: () {
              context.router.push(
                TenantAdminDiscoveryFilterSurfaceRoute(
                  surfaceKey: surface.key,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  IconData _iconForSurface(
    TenantAdminDiscoveryFilterSurfaceDefinition surface,
  ) {
    return switch (surface.key) {
      'public_map.primary' => Icons.map_outlined,
      'home.events' => Icons.event_outlined,
      'discovery.account_profiles' => Icons.groups_outlined,
      _ => Icons.filter_alt_outlined,
    };
  }
}

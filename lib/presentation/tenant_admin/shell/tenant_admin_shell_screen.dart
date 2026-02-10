import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminShellScreen extends StatefulWidget {
  const TenantAdminShellScreen({super.key});

  @override
  State<TenantAdminShellScreen> createState() =>
      _TenantAdminShellScreenState();
}

class _TenantAdminShellScreenState extends State<TenantAdminShellScreen> {
  static const _railBreakpoint = 900.0;
  final TenantAdminShellController _controller =
      GetIt.I.get<TenantAdminShellController>();

  final List<_AdminDestination> _destinations = const [
    _AdminDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: TenantAdminDashboardRoute(),
      routeNames: {
        TenantAdminDashboardRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Contas',
      icon: Icons.account_box_outlined,
      selectedIcon: Icons.account_box,
      route: TenantAdminAccountsListRoute(),
      routeNames: {
        TenantAdminAccountsListRoute.name,
        TenantAdminAccountCreateRoute.name,
        TenantAdminAccountDetailRoute.name,
        TenantAdminAccountProfileCreateRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Organizações',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment,
      route: TenantAdminOrganizationsListRoute(),
      routeNames: {
        TenantAdminOrganizationsListRoute.name,
        TenantAdminOrganizationCreateRoute.name,
        TenantAdminOrganizationDetailRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Tipos',
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
      route: TenantAdminProfileTypesListRoute(),
      routeNames: {
        TenantAdminProfileTypesListRoute.name,
        TenantAdminProfileTypeCreateRoute.name,
        TenantAdminProfileTypeEditRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Tipos de Ativo',
      icon: Icons.layers_outlined,
      selectedIcon: Icons.layers,
      route: TenantAdminStaticProfileTypesListRoute(),
      routeNames: {
        TenantAdminStaticProfileTypesListRoute.name,
        TenantAdminStaticProfileTypeCreateRoute.name,
        TenantAdminStaticProfileTypeEditRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Taxonomias',
      icon: Icons.account_tree_outlined,
      selectedIcon: Icons.account_tree,
      route: TenantAdminTaxonomiesListRoute(),
      routeNames: {
        TenantAdminTaxonomiesListRoute.name,
        TenantAdminTaxonomyTermsRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Ativos',
      icon: Icons.place_outlined,
      selectedIcon: Icons.place,
      route: TenantAdminStaticAssetsListRoute(),
      routeNames: {
        TenantAdminStaticAssetsListRoute.name,
        TenantAdminStaticAssetCreateRoute.name,
        TenantAdminStaticAssetEditRoute.name,
      },
    ),
  ];

  final Set<String> _fullScreenRoutes = const {
    TenantAdminAccountCreateRoute.name,
    TenantAdminAccountDetailRoute.name,
    TenantAdminAccountProfileCreateRoute.name,
    TenantAdminOrganizationCreateRoute.name,
    TenantAdminOrganizationDetailRoute.name,
    TenantAdminProfileTypeCreateRoute.name,
    TenantAdminProfileTypeEditRoute.name,
    TenantAdminStaticProfileTypeCreateRoute.name,
    TenantAdminStaticProfileTypeEditRoute.name,
    TenantAdminLocationPickerRoute.name,
    TenantAdminStaticAssetCreateRoute.name,
    TenantAdminStaticAssetEditRoute.name,
  };

  int _selectedIndex(String? routeName) {
    for (var i = 0; i < _destinations.length; i++) {
      if (_destinations[i].routeNames.contains(routeName)) {
        return i;
      }
    }
    return 0;
  }

  String _titleForRoute(String? routeName) {
    if (routeName == TenantAdminAccountsListRoute.name) {
      return 'Contas';
    }
    if (routeName == TenantAdminOrganizationsListRoute.name) {
      return 'Organizações';
    }
    if (routeName == TenantAdminProfileTypesListRoute.name) {
      return 'Tipos de Perfil';
    }
    if (routeName == TenantAdminStaticProfileTypesListRoute.name) {
      return 'Tipos de Ativo';
    }
    if (routeName == TenantAdminTaxonomiesListRoute.name ||
        routeName == TenantAdminTaxonomyTermsRoute.name) {
      return 'Taxonomias';
    }
    if (routeName == TenantAdminStaticAssetsListRoute.name ||
        routeName == TenantAdminStaticAssetCreateRoute.name ||
        routeName == TenantAdminStaticAssetEditRoute.name) {
      return 'Ativos estaticos';
    }
    return 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder(
      streamValue: _controller.modeStreamValue,
      builder: (context, mode) {
        _handleModeChange(mode);
        final router = context.router;
        final currentName = router.topRoute.name;
        final selectedIndex = _selectedIndex(currentName);
        final showShellAppBar = !_fullScreenRoutes.contains(currentName);

        final navRail = NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            router.replace(_destinations[index].route);
          },
          labelType: NavigationRailLabelType.all,
          destinations: _destinations
              .map(
                (destination) => NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
              )
              .toList(growable: false),
          leading: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.admin_panel_settings_outlined),
                ),
                const SizedBox(height: 12),
                IconButton(
                  tooltip: 'Perfil',
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => _controller.switchToUserMode(),
                ),
              ],
            ),
          ),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _railBreakpoint;
            return Scaffold(
              appBar: showShellAppBar
                  ? AppBar(
                      title: Text(_titleForRoute(currentName)),
                      actions: [
                        TextButton.icon(
                          onPressed: () => _controller.switchToUserMode(),
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Perfil'),
                        ),
                      ],
                    )
                  : null,
              body: isWide
                  ? Row(
                      children: [
                        navRail,
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: AutoRouter(
                            key: const ValueKey('tenant-admin-shell-router'),
                          ),
                        ),
                      ],
                    )
                  : AutoRouter(
                      key: const ValueKey('tenant-admin-shell-router'),
                    ),
              bottomNavigationBar: isWide
                  ? null
                  : NavigationBar(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: (index) {
                        router.replace(_destinations[index].route);
                      },
                      destinations: _destinations
                          .map(
                            (destination) => NavigationDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: destination.label,
                            ),
                          )
                          .toList(growable: false),
                    ),
            );
          },
        );
      },
    );
  }

  void _handleModeChange(AdminMode mode) {
    if (mode != AdminMode.user) return;
    context.router.replaceAll([const ProfileRoute()]);
  }
}

class _AdminDestination {
  const _AdminDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.routeNames,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final PageRouteInfo route;
  final Set<String> routeNames;
}

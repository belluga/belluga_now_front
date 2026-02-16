import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/widgets/tenant_selection_gate.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/widgets/tenant_selection_loading_gate.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class TenantAdminShellScreen extends StatefulWidget {
  const TenantAdminShellScreen({super.key});

  @override
  State<TenantAdminShellScreen> createState() => _TenantAdminShellScreenState();
}

class _TenantAdminShellScreenState extends State<TenantAdminShellScreen> {
  static const _railBreakpoint = 900.0;
  final TenantAdminShellController _controller =
      GetIt.I.get<TenantAdminShellController>();

  final List<_AdminDestination> _destinations = const [
    _AdminDestination(
      label: 'Início',
      title: 'Visão geral',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: TenantAdminDashboardRoute(),
      routeNames: {
        TenantAdminDashboardRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Eventos',
      title: 'Eventos',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      route: TenantAdminEventsRoute(),
      routeNames: {
        TenantAdminEventsRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Contas',
      title: 'Contas',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      route: TenantAdminAccountsListRoute(),
      routeNames: {
        TenantAdminAccountsListRoute.name,
        TenantAdminAccountCreateRoute.name,
        TenantAdminAccountDetailRoute.name,
        TenantAdminAccountProfileCreateRoute.name,
        TenantAdminAccountProfileEditRoute.name,
        TenantAdminOrganizationsListRoute.name,
        TenantAdminOrganizationCreateRoute.name,
        TenantAdminOrganizationDetailRoute.name,
        TenantAdminProfileTypesListRoute.name,
        TenantAdminProfileTypeDetailRoute.name,
        TenantAdminProfileTypeCreateRoute.name,
        TenantAdminProfileTypeEditRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Ativos',
      title: 'Ativos estáticos',
      icon: Icons.place_outlined,
      selectedIcon: Icons.place,
      route: TenantAdminStaticAssetsListRoute(),
      routeNames: {
        TenantAdminStaticAssetsListRoute.name,
        TenantAdminStaticAssetDetailRoute.name,
        TenantAdminStaticAssetCreateRoute.name,
        TenantAdminStaticAssetEditRoute.name,
        TenantAdminStaticProfileTypesListRoute.name,
        TenantAdminStaticProfileTypeDetailRoute.name,
        TenantAdminStaticProfileTypeCreateRoute.name,
        TenantAdminStaticProfileTypeEditRoute.name,
        TenantAdminTaxonomiesListRoute.name,
        TenantAdminTaxonomyCreateRoute.name,
        TenantAdminTaxonomyEditRoute.name,
        TenantAdminTaxonomyTermsRoute.name,
        TenantAdminTaxonomyTermDetailRoute.name,
        TenantAdminTaxonomyTermCreateRoute.name,
        TenantAdminTaxonomyTermEditRoute.name,
      },
    ),
    _AdminDestination(
      label: 'Config',
      title: 'Configurações',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: TenantAdminSettingsRoute(),
      routeNames: {
        TenantAdminSettingsRoute.name,
      },
    ),
  ];

  final Set<String> _fullScreenRoutes = const {
    TenantAdminAccountCreateRoute.name,
    TenantAdminAccountDetailRoute.name,
    TenantAdminAccountProfileCreateRoute.name,
    TenantAdminAccountProfileEditRoute.name,
    TenantAdminOrganizationCreateRoute.name,
    TenantAdminOrganizationDetailRoute.name,
    TenantAdminProfileTypeDetailRoute.name,
    TenantAdminProfileTypeCreateRoute.name,
    TenantAdminProfileTypeEditRoute.name,
    TenantAdminStaticProfileTypeDetailRoute.name,
    TenantAdminStaticProfileTypeCreateRoute.name,
    TenantAdminStaticProfileTypeEditRoute.name,
    TenantAdminTaxonomyTermsRoute.name,
    TenantAdminTaxonomyCreateRoute.name,
    TenantAdminTaxonomyEditRoute.name,
    TenantAdminTaxonomyTermDetailRoute.name,
    TenantAdminTaxonomyTermCreateRoute.name,
    TenantAdminTaxonomyTermEditRoute.name,
    TenantAdminLocationPickerRoute.name,
    TenantAdminStaticAssetDetailRoute.name,
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
    final index = _selectedIndex(routeName);
    return _destinations[index].title;
  }

  List<Widget> _buildContextualActions({
    required BuildContext context,
    required String? routeName,
  }) {
    if (routeName == TenantAdminAccountsListRoute.name) {
      return [
        IconButton(
          tooltip: 'Tipos de Perfil',
          onPressed: () {
            context.router.push(const TenantAdminProfileTypesListRoute());
          },
          icon: const Icon(Icons.category_outlined),
        ),
      ];
    }
    if (routeName == TenantAdminStaticAssetsListRoute.name) {
      return [
        IconButton(
          tooltip: 'Tipos de Ativo',
          onPressed: () {
            context.router.push(const TenantAdminStaticProfileTypesListRoute());
          },
          icon: const Icon(Icons.layers_outlined),
        ),
      ];
    }
    return const [];
  }

  String? _resolveCurrentRouteName(BuildContext context) =>
      context.topRoute.name;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<List<LandlordTenantOption>>(
      streamValue: _controller.availableTenantsStreamValue,
      builder: (context, availableTenants) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.isTenantSelectionResolvingStreamValue,
          builder: (context, isTenantSelectionResolving) {
            return StreamValueBuilder<String?>(
              streamValue: _controller.selectedTenantDomainStreamValue,
              builder: (context, selectedTenantDomain) {
                if (selectedTenantDomain == null ||
                    selectedTenantDomain.trim().isEmpty) {
                  if (isTenantSelectionResolving) {
                    return const TenantSelectionLoadingGate();
                  }
                  return TenantSelectionGate(
                    tenants: availableTenants,
                    onSelectTenant: _controller.selectTenantDomain,
                  );
                }

                final router = context.router;
                final currentName = _resolveCurrentRouteName(context);
                final selectedIndex = _selectedIndex(currentName);
                final showShellScaffoldChrome =
                    !_fullScreenRoutes.contains(currentName);
                final selectedTenantLabel = _controller.resolveTenantLabel(
                  tenants: availableTenants,
                  tenantDomain: selectedTenantDomain,
                );
                final canChangeTenant = availableTenants.length > 1;
                final shellRouterKey =
                    ValueKey('tenant-admin-shell-router-$selectedTenantDomain');

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
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(
                            Icons.admin_panel_settings_outlined,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 88,
                          child: Text(
                            selectedTenantLabel,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        if (canChangeTenant) ...[
                          const SizedBox(height: 8),
                          IconButton(
                            tooltip: 'Trocar tenant',
                            onPressed: _controller.clearTenantSelection,
                            icon: const Icon(Icons.swap_horiz_outlined),
                          ),
                        ],
                      ],
                    ),
                  ),
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= _railBreakpoint;
                    return Scaffold(
                      appBar: showShellScaffoldChrome
                          ? AppBar(
                              title: Text(_titleForRoute(currentName)),
                              actions: [
                                ..._buildContextualActions(
                                  context: context,
                                  routeName: currentName,
                                ),
                                if (canChangeTenant)
                                  TextButton.icon(
                                    onPressed: _controller.clearTenantSelection,
                                    icon: const Icon(
                                      Icons.swap_horiz_outlined,
                                    ),
                                    label: Text(selectedTenantLabel),
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
                                    key: shellRouterKey,
                                  ),
                                ),
                              ],
                            )
                          : AutoRouter(
                              key: shellRouterKey,
                            ),
                      bottomNavigationBar: isWide || !showShellScaffoldChrome
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
                                      selectedIcon:
                                          Icon(destination.selectedIcon),
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
          },
        );
      },
    );
  }
}

class _AdminDestination {
  const _AdminDestination({
    required this.label,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.routeNames,
  });

  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final PageRouteInfo route;
  final Set<String> routeNames;
}

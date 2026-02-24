import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/theme/tenant_admin_scope_theme.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/widgets/tenant_admin_shell_header.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/widgets/tenant_selection_gate.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/widgets/tenant_selection_loading_gate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantAdminShellScreen extends StatefulWidget {
  const TenantAdminShellScreen({super.key});

  @override
  State<TenantAdminShellScreen> createState() => _TenantAdminShellScreenState();
}

class _TenantAdminShellScreenState extends State<TenantAdminShellScreen> {
  static const _railBreakpoint = 980.0;
  static const _desktopMaxWidth = 1480.0;
  final TenantAdminShellController _controller =
      GetIt.I.get<TenantAdminShellController>();
  final AppDataRepositoryContract _appDataRepository =
      GetIt.I.get<AppDataRepositoryContract>();
  String? _lastNormalizedPathEnqueued;

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
        TenantAdminSettingsLocalPreferencesRoute.name,
        TenantAdminSettingsVisualIdentityRoute.name,
        TenantAdminSettingsTechnicalIntegrationsRoute.name,
        TenantAdminSettingsEnvironmentSnapshotRoute.name,
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

  final Set<String> _scopedSectionAppBarRoutes = const {
    TenantAdminSettingsLocalPreferencesRoute.name,
    TenantAdminSettingsVisualIdentityRoute.name,
    TenantAdminSettingsTechnicalIntegrationsRoute.name,
    TenantAdminSettingsEnvironmentSnapshotRoute.name,
  };

  int _selectedIndex(String? routeName) {
    for (var i = 0; i < _destinations.length; i++) {
      if (_destinations[i].routeNames.contains(routeName)) {
        return i;
      }
    }
    return 0;
  }

  _AdminDestination? _destinationForRoute(String? routeName) {
    if (routeName == null) {
      return null;
    }
    for (final destination in _destinations) {
      if (destination.routeNames.contains(routeName)) {
        return destination;
      }
    }
    return null;
  }

  String _titleForRoute(String? routeName) {
    final index = _selectedIndex(routeName);
    return _destinations[index].title;
  }

  String? _childRouteTitle(String? routeName) {
    return switch (routeName) {
      TenantAdminSettingsLocalPreferencesRoute.name => 'Preferências',
      TenantAdminSettingsVisualIdentityRoute.name => 'Identidade visual',
      TenantAdminSettingsTechnicalIntegrationsRoute.name =>
        'Integrações técnicas',
      TenantAdminSettingsEnvironmentSnapshotRoute.name =>
        'Snapshot do environment',
      TenantAdminOrganizationsListRoute.name => 'Organizações',
      TenantAdminProfileTypesListRoute.name => 'Tipos de perfil',
      TenantAdminStaticProfileTypesListRoute.name => 'Tipos de ativo',
      TenantAdminTaxonomiesListRoute.name => 'Taxonomias',
      _ => null,
    };
  }

  void _navigateBackFromHeader(
    BuildContext context, {
    required String? routeName,
  }) {
    final router = context.router;
    if (router.canPop()) {
      router.pop();
      return;
    }
    final destination = _destinationForRoute(routeName);
    if (destination != null) {
      router.replace(destination.route);
    }
  }

  _ShellHeaderContext _headerContextForRoute(String? routeName) {
    final destination = _destinationForRoute(routeName);
    if (destination == null) {
      return _ShellHeaderContext(title: _titleForRoute(routeName));
    }

    final isRootRoute = routeName == destination.route.routeName;
    if (isRootRoute) {
      return _ShellHeaderContext(title: destination.title);
    }

    final childTitle = _childRouteTitle(routeName) ?? destination.title;
    return _ShellHeaderContext(
      title: childTitle,
      breadcrumbs: <String>[destination.title],
      canGoBack: true,
    );
  }

  List<Widget> _buildContextualActions({
    required BuildContext context,
    required String? routeName,
  }) {
    if (routeName == TenantAdminAccountsListRoute.name) {
      return [
        IconButton.filledTonal(
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
        IconButton.filledTonal(
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

  void _ensureResolvedWebPath(BuildContext context) {
    if (!kIsWeb) {
      return;
    }
    final router = context.router;
    final routeData = context.topRoute;
    final currentPath = router.currentPath;
    if (!currentPath.contains('/:')) {
      return;
    }

    final resolved = _resolveRouteMatchPath(routeData);
    if (resolved == null || resolved == currentPath) {
      return;
    }
    if (_lastNormalizedPathEnqueued == resolved) {
      return;
    }
    _lastNormalizedPathEnqueued = resolved;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final liveRouter = context.router;
      if (liveRouter.currentPath == resolved) {
        return;
      }
      liveRouter.replacePath(resolved);
    });
  }

  void _handleTenantSelection(String tenantDomain) {
    unawaited(_handleTenantSelectionAsync(tenantDomain));
  }

  Future<void> _handleTenantSelectionAsync(String tenantDomain) async {
    if (!_isLandlordEnvironment()) {
      _controller.selectTenantDomain(tenantDomain);
      return;
    }

    final targetUrl = _buildTenantSurfaceUrl(
      tenantDomain: tenantDomain,
      path: '/admin',
    );
    if (targetUrl == null) {
      _controller.selectTenantDomain(tenantDomain);
      return;
    }

    await _openRedirectLink(targetUrl);
  }

  void _handlePreviewTenantPublic() {
    unawaited(_handlePreviewTenantPublicAsync());
  }

  Future<void> _handlePreviewTenantPublicAsync() async {
    final selectedTenantDomain = _controller.selectedTenantDomain;

    if (_isLandlordEnvironment() &&
        selectedTenantDomain != null &&
        !_isCurrentHost(selectedTenantDomain)) {
      final targetUrl = _buildTenantSurfaceUrl(
        tenantDomain: selectedTenantDomain,
        path: '/',
      );
      if (targetUrl != null) {
        await _openRedirectLink(targetUrl);
        return;
      }
    }

    if (!mounted) {
      return;
    }
    context.router.replaceAll([const TenantHomeRoute()]);
  }

  bool _isLandlordEnvironment() {
    return _appDataRepository.appData.typeValue.value ==
        EnvironmentType.landlord;
  }

  bool _isCurrentHost(String tenantDomain) {
    final currentHost =
        _appDataRepository.appData.hostname.trim().toLowerCase();
    final candidate = _parseAsUri(tenantDomain);
    if (candidate == null) {
      return false;
    }
    return candidate.host.trim().toLowerCase() == currentHost;
  }

  Future<void> _openRedirectLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }

    final launched = await launchUrl(uri, webOnlyWindowName: '_self');
    if (!launched) {
      debugPrint('[TenantAdmin] Redirect link failed for $url');
    }
  }

  String? _buildTenantSurfaceUrl({
    required String tenantDomain,
    required String path,
  }) {
    final parsedTenant = _parseAsUri(tenantDomain);
    if (parsedTenant == null || parsedTenant.host.trim().isEmpty) {
      return null;
    }

    final hasScheme = tenantDomain.contains('://');
    final landlordOrigin = _parseAsUri(BellugaConstants.landlordDomain);
    final scheme = hasScheme
        ? parsedTenant.scheme.toLowerCase()
        : landlordOrigin?.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return null;
    }

    final port = parsedTenant.hasPort
        ? parsedTenant.port
        : (landlordOrigin != null && landlordOrigin.hasPort)
            ? landlordOrigin.port
            : null;

    return Uri(
      scheme: scheme,
      host: parsedTenant.host,
      port: port,
      path: path,
    ).toString();
  }

  Uri? _parseAsUri(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return Uri.tryParse(
      normalized.contains('://') ? normalized : 'https://$normalized',
    );
  }

  String? _resolveRouteMatchPath(RouteData routeData) {
    final rawMatch = routeData.match;
    if (rawMatch.isEmpty) {
      return null;
    }
    var resolved = rawMatch;
    routeData.params.rawMap.forEach((key, value) {
      if (value == null) {
        return;
      }
      resolved = resolved.replaceAll(
        ':$key',
        Uri.encodeComponent(value.toString()),
      );
    });
    if (resolved.contains('/:')) {
      return null;
    }
    final query = routeData.queryParams.rawMap;
    if (query.isEmpty) {
      return resolved;
    }
    final queryParameters = <String, String>{};
    query.forEach((key, value) {
      if (value != null) {
        queryParameters[key] = value.toString();
      }
    });
    return Uri.parse(resolved)
        .replace(
          queryParameters: queryParameters.isEmpty ? null : queryParameters,
        )
        .toString();
  }

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  Widget _buildRail(
    BuildContext context,
    int selectedIndex,
    StackRouter router,
    String selectedTenantLabel,
    bool canChangeTenant,
  ) {
    return NavigationRail(
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
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 10),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: const Icon(Icons.admin_panel_settings_outlined),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 98,
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
  }

  Widget _buildWorkspaceSurface({
    required BuildContext context,
    required Widget child,
  }) {
    return child;
  }

  Widget _buildNavigationSurface({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _buildMobileNavigation(
    BuildContext context,
    int selectedIndex,
    StackRouter router,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: _buildNavigationSurface(
        context: context,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          backgroundColor: Colors.transparent,
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
      ),
    );
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
                    onSelectTenant: _handleTenantSelection,
                  );
                }

                final router = context.router;
                final currentName = _resolveCurrentRouteName(context);
                _ensureResolvedWebPath(context);
                final selectedIndex = _selectedIndex(currentName);
                final showShellScaffoldChrome =
                    !_fullScreenRoutes.contains(currentName);
                final showShellGlobalHeader = showShellScaffoldChrome &&
                    !_scopedSectionAppBarRoutes.contains(currentName);
                final selectedTenantLabel = _controller.resolveTenantLabel(
                  tenants: availableTenants,
                  tenantDomain: selectedTenantDomain,
                );
                final canChangeTenant = availableTenants.length > 1;
                final shellRouterKey =
                    ValueKey('tenant-admin-shell-router-$selectedTenantDomain');
                final scopedTheme = TenantAdminScopeTheme.resolve(
                  Theme.of(context),
                );
                final headerContext = _headerContextForRoute(currentName);

                return Theme(
                  data: scopedTheme,
                  child: Builder(
                    builder: (scopeContext) {
                      final scopedActions = _buildContextualActions(
                        context: scopeContext,
                        routeName: currentName,
                      );
                      final shellActions = <Widget>[
                        IconButton.filledTonal(
                          tooltip: 'Preview tenant public',
                          onPressed: _handlePreviewTenantPublic,
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        ...scopedActions,
                      ];

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide =
                              constraints.maxWidth >= _railBreakpoint;

                          if (isWide) {
                            final rail = _buildRail(
                              scopeContext,
                              selectedIndex,
                              router,
                              selectedTenantLabel,
                              canChangeTenant,
                            );
                            return Scaffold(
                              body: SafeArea(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: _desktopMaxWidth,
                                    ),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              14, 14, 0, 14),
                                          child: _buildNavigationSurface(
                                            context: scopeContext,
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                              bottom: 8,
                                            ),
                                            child: rail,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              14,
                                              14,
                                              14,
                                              14,
                                            ),
                                            child: Column(
                                              children: [
                                                showShellGlobalHeader
                                                    ? TenantAdminShellHeader(
                                                        title:
                                                            headerContext.title,
                                                        breadcrumbs:
                                                            headerContext
                                                                .breadcrumbs,
                                                        showBackButton: false,
                                                        onBack: () =>
                                                            _navigateBackFromHeader(
                                                          scopeContext,
                                                          routeName:
                                                              currentName,
                                                        ),
                                                        tenantLabel:
                                                            selectedTenantLabel,
                                                        canChangeTenant:
                                                            canChangeTenant,
                                                        onChangeTenant: _controller
                                                            .clearTenantSelection,
                                                        actions: shellActions,
                                                      )
                                                    : const SizedBox.shrink(),
                                                SizedBox(
                                                  height: showShellGlobalHeader
                                                      ? 14
                                                      : 0,
                                                ),
                                                Expanded(
                                                  child: _buildWorkspaceSurface(
                                                    context: scopeContext,
                                                    child: AutoRouter(
                                                      key: shellRouterKey,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return Scaffold(
                            body: SafeArea(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                child: Column(
                                  children: [
                                    showShellGlobalHeader
                                        ? TenantAdminShellHeader(
                                            title: headerContext.title,
                                            breadcrumbs:
                                                headerContext.breadcrumbs,
                                            showBackButton:
                                                headerContext.canGoBack,
                                            onBack: () =>
                                                _navigateBackFromHeader(
                                              scopeContext,
                                              routeName: currentName,
                                            ),
                                            tenantLabel: selectedTenantLabel,
                                            canChangeTenant: canChangeTenant,
                                            onChangeTenant: _controller
                                                .clearTenantSelection,
                                            actions: shellActions,
                                          )
                                        : const SizedBox.shrink(),
                                    SizedBox(
                                      height: showShellGlobalHeader ? 10 : 0,
                                    ),
                                    Expanded(
                                      child: _buildWorkspaceSurface(
                                        context: scopeContext,
                                        child: AutoRouter(
                                          key: shellRouterKey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            bottomNavigationBar: showShellScaffoldChrome
                                ? _buildMobileNavigation(
                                    scopeContext,
                                    selectedIndex,
                                    router,
                                  )
                                : null,
                          );
                        },
                      );
                    },
                  ),
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

class _ShellHeaderContext {
  const _ShellHeaderContext({
    required this.title,
    this.breadcrumbs = const <String>[],
    this.canGoBack = false,
  });

  final String title;
  final List<String> breadcrumbs;
  final bool canGoBack;
}

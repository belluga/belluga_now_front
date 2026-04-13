import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/presentation/landlord_area/auth/widgets/landlord_login_sheet.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_login_controller.dart';
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

  final List<_AdminDestination> _destinations = const [
    _AdminDestination(
      label: 'Início',
      title: 'Visão geral',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: TenantAdminDashboardRoute(),
      section: AdminShellSection.dashboard,
    ),
    _AdminDestination(
      label: 'Eventos',
      title: 'Eventos',
      icon: Icons.event_outlined,
      selectedIcon: Icons.event,
      route: TenantAdminEventsRoute(),
      section: AdminShellSection.events,
    ),
    _AdminDestination(
      label: 'Contas',
      title: 'Contas',
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups,
      route: TenantAdminAccountsListRoute(),
      section: AdminShellSection.accounts,
    ),
    _AdminDestination(
      label: 'Ativos',
      title: 'Ativos estáticos',
      icon: Icons.place_outlined,
      selectedIcon: Icons.place,
      route: TenantAdminStaticAssetsListRoute(),
      section: AdminShellSection.assets,
    ),
    _AdminDestination(
      label: 'Config',
      title: 'Configurações',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: TenantAdminSettingsRoute(),
      section: AdminShellSection.settings,
    ),
  ];

  int _selectedIndex(AdminShellSection? section) {
    for (var i = 0; i < _destinations.length; i++) {
      if (_destinations[i].section == section) {
        return i;
      }
    }
    return 0;
  }

  _AdminDestination? _destinationForSection(AdminShellSection? section) {
    if (section == null) {
      return null;
    }
    for (final destination in _destinations) {
      if (destination.section == section) {
        return destination;
      }
    }
    return null;
  }

  String? _childRouteTitle(String? routeName) {
    return switch (routeName) {
      TenantAdminSettingsLocalPreferencesRoute.name => 'Preferências',
      TenantAdminSettingsVisualIdentityRoute.name => 'Identidade visual',
      TenantAdminSettingsDomainsRoute.name => 'Domínios',
      TenantAdminSettingsTechnicalIntegrationsRoute.name =>
        'Integrações técnicas',
      TenantAdminSettingsEnvironmentSnapshotRoute.name =>
        'Snapshot do environment',
      TenantAdminOrganizationsListRoute.name => 'Organizações',
      TenantAdminProfileTypesListRoute.name => 'Tipos de perfil',
      TenantAdminStaticProfileTypesListRoute.name => 'Tipos de ativo',
      TenantAdminTaxonomiesListRoute.name => 'Taxonomias',
      TenantAdminEventTypesRoute.name => 'Tipos de evento',
      _ => null,
    };
  }

  _ShellHeaderContext _headerContextForRoute({
    required AdminShellSection? section,
    required bool isDashboardRoot,
    required bool isSectionRoot,
    required bool isAdminInternal,
    required String? routeName,
  }) {
    final destination = _destinationForSection(section);
    if (destination == null) {
      return const _ShellHeaderContext(title: 'Área admin');
    }

    final isRootRoute = isDashboardRoot || isSectionRoot;
    if (isRootRoute) {
      return _ShellHeaderContext(title: destination.title);
    }

    final childTitle = _childRouteTitle(routeName) ?? destination.title;
    return _ShellHeaderContext(
      title: childTitle,
      breadcrumbs: <String>[destination.title],
      canGoBack: isAdminInternal,
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
    if (routeName == TenantAdminEventsRoute.name) {
      return [
        IconButton.filledTonal(
          tooltip: 'Tipos de evento',
          onPressed: () {
            context.router.push(const TenantAdminEventTypesRoute());
          },
          icon: const Icon(Icons.category_outlined),
        ),
      ];
    }
    return const [];
  }

  void _handleTenantSelection(String tenantDomain) {
    unawaited(_handleTenantSelectionAsync(tenantDomain));
  }

  Future<void> _handleTenantSelectionAsync(String tenantDomain) async {
    if (!_controller.isLandlordEnvironment || !kIsWeb) {
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
    final selectedTenantDomain = _controller.selectedTenantDomain;

    if (_controller.isLandlordEnvironment &&
        selectedTenantDomain != null &&
        !_isCurrentOrigin(selectedTenantDomain)) {
      final targetUrl = _buildTenantSurfaceUrl(
        tenantDomain: selectedTenantDomain,
        path: '/',
      );
      if (targetUrl != null) {
        unawaited(_openRedirectLink(targetUrl));
        return;
      }
    }

    if (!mounted) {
      return;
    }
    context.router.replaceAll([const TenantHomeRoute()]);
  }

  Future<void> _openTenantDomainAdminLogin() async {
    final loginController = GetIt.I.get<TenantAdminShellLoginController>();
    final didLogin = await showLandlordLoginSheet(
      context,
      controller: loginController,
    );
    if (!mounted) {
      return;
    }
    if (!didLogin) {
      return;
    }

    _controller.init();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildTenantAdminAuthGate() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenant admin login'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin access required on this domain',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To access `/admin` on this tenant domain, sign in as landlord in this same domain.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _openTenantDomainAdminLogin,
                      icon: const Icon(Icons.login),
                      label: const Text('Entrar como Admin'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        context.router.replaceAll([const TenantHomeRoute()]);
                      },
                      child: const Text('Voltar para home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isCurrentOrigin(String tenantDomain) {
    final current = Uri.tryParse(_controller.currentAppHref);
    final candidate = _parseAsUri(tenantDomain);
    if (current == null || candidate == null) {
      return false;
    }

    if (candidate.host.trim().toLowerCase() !=
        current.host.trim().toLowerCase()) {
      return false;
    }

    if (_effectivePort(candidate) != _effectivePort(current)) {
      return false;
    }

    if (tenantDomain.contains('://')) {
      return candidate.scheme.toLowerCase() == current.scheme.toLowerCase();
    }

    return true;
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
        : hasScheme
            ? null
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

  int? _effectivePort(Uri uri) {
    if (uri.hasPort) {
      return uri.port;
    }
    return switch (uri.scheme.toLowerCase()) {
      'http' => 80,
      'https' => 443,
      _ => null,
    };
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
    required Widget child,
    required RouteBackPolicy backPolicy,
  }) {
    return RouteBackScope(
      backPolicy: backPolicy,
      child: child,
    );
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
    if (_controller.isTenantEnvironment &&
        !_controller.hasLocalLandlordSession) {
      return _buildTenantAdminAuthGate();
    }

    return StreamValueBuilder<List<LandlordTenantOption>>(
      streamValue: _controller.availableTenantsStreamValue,
      builder: (context, availableTenants) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.isTenantSelectionResolvingStreamValue,
          builder: (context, isTenantSelectionResolving) {
            return StreamValueBuilder<String?>(
              streamValue: _controller.selectedTenantDomainStreamValue,
              builder: (context, selectedTenantDomain) {
                final hasSelectedTenantDomain =
                    selectedTenantDomain?.trim().isNotEmpty ?? false;
                if (!hasSelectedTenantDomain) {
                  if (isTenantSelectionResolving) {
                    return const TenantSelectionLoadingGate();
                  }
                  return TenantSelectionGate(
                    tenants: availableTenants,
                    onSelectTenant: _handleTenantSelection,
                  );
                }

                final router = context.router;
                final routeData = context.topRoute;
                final currentName = routeData.name;
                final adminSection =
                    resolveCanonicalAdminShellSection(routeData);
                final selectedIndex = _selectedIndex(adminSection);
                final routeChromeMode =
                    resolveCanonicalRouteChromeMode(routeData);
                final isAdminDashboardRoot =
                    isCanonicalAdminDashboardRoot(routeData);
                final isAdminSectionRoot =
                    isCanonicalAdminSectionRoot(routeData);
                final isAdminInternal = isCanonicalAdminInternal(routeData);
                final showShellScaffoldChrome =
                    routeChromeMode != RouteChromeMode.fullscreen;
                final showShellGlobalHeader = showShellScaffoldChrome &&
                    routeChromeMode != RouteChromeMode.scopedSectionAppBar;
                final selectedTenantLabel = _controller.resolveTenantLabel(
                  tenants: availableTenants,
                  tenantDomain: selectedTenantDomain!,
                );
                final canChangeTenant = availableTenants.length > 1;
                final shellRouterKey =
                    ValueKey('tenant-admin-shell-router-$selectedTenantDomain');
                final scopedTheme = TenantAdminScopeTheme.resolve(
                  Theme.of(context),
                );
                final headerContext = _headerContextForRoute(
                  section: adminSection,
                  isDashboardRoot: isAdminDashboardRoot,
                  isSectionRoot: isAdminSectionRoot,
                  isAdminInternal: isAdminInternal,
                  routeName: currentName,
                );
                final routeBackPolicy =
                    buildCanonicalRouteBackPolicyForRouteData(
                  routeData: routeData,
                );

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
                              resizeToAvoidBottomInset: false,
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
                                                        showBackButton:
                                                            headerContext
                                                                .canGoBack,
                                                        onBack: routeBackPolicy
                                                            .handleBack,
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
                                                    backPolicy: routeBackPolicy,
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
                            resizeToAvoidBottomInset: false,
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
                                            onBack: routeBackPolicy.handleBack,
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
                                        backPolicy: routeBackPolicy,
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
    required this.section,
  });

  final String label;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final PageRouteInfo route;
  final AdminShellSection section;
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

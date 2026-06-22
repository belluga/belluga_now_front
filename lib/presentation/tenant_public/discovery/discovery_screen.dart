import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_discovery_filters/belluga_discovery_filters.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/shared/favorites/account_profile_favorite_auth_gate.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_filter_header_delegate.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_live_now_section.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_nearby_row.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_partner_grid.dart';
import 'package:belluga_now/presentation/shared/widgets/discovery_filter_visual_icon.dart';
import 'package:belluga_now/presentation/shared/widgets/route_back_scope.dart';
import 'package:belluga_now/presentation/shared/widgets/main_logo.dart';
import 'package:belluga_now/presentation/shared/widgets/size_reporting_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({
    super.key,
    this.isWebRuntime = kIsWeb,
  });

  final bool isWebRuntime;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  static const double _headerCollapsedExtent = 72;
  static const double _defaultFilterPanelExtent = 60;

  final DiscoveryScreenController _controller =
      GetIt.I.get<DiscoveryScreenController>();
  double _filterPanelExtent = _defaultFilterPanelExtent;

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    final backPolicy = buildCanonicalCurrentRouteBackPolicy(
      context,
      consumeBackNavigationIfNeeded: _controller.consumeBackNavigationIfNeeded,
    );
    return RouteBackScope(
      backPolicy: backPolicy,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const ValueKey<String>('discovery-safe-back-button'),
            tooltip: 'Voltar',
            onPressed: backPolicy.handleBack,
            icon: const Icon(Icons.arrow_back),
          ),
          title: StreamValueBuilder<bool>(
            streamValue: _controller.isSearchingStreamValue,
            builder: (context, isSearching) {
              final colorScheme = Theme.of(context).colorScheme;
              return isSearching
                  ? TextField(
                      controller: _controller.searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar artistas, locais...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      style: TextStyle(color: colorScheme.onSurface),
                    )
                  : _buildBrandAppBarTitle();
            },
          ),
          actions: [
            StreamValueBuilder<bool>(
              streamValue: _controller.isSearchingStreamValue,
              builder: (context, isSearching) {
                if (!isSearching) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  tooltip: 'Fechar busca',
                  icon: const Icon(Icons.close),
                  onPressed: _controller.toggleSearch,
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: StreamValueBuilder<bool>(
            streamValue: _controller.isLoadingStreamValue,
            builder: (context, isLoading) {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildFeed(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeed(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: _controller.isSearchingStreamValue,
      builder: (context, isSearching) {
        return StreamValueBuilder<String?>(
          streamValue: _controller.selectedTypeFilterStreamValue,
          builder: (context, selectedType) {
            return StreamValueBuilder<String>(
              streamValue: _controller.searchQueryStreamValue,
              builder: (context, query) {
                final trimmedQuery = query.trim();
                final hasSelectedType = selectedType?.isNotEmpty ?? false;
                final showSections =
                    !isSearching && !hasSelectedType && trimmedQuery.isEmpty;
                return StreamValueBuilder<Set<String>>(
                  streamValue: _controller.favoriteIdsStream,
                  builder: (context, favorites) {
                    return StreamValueBuilder<List<AccountProfileModel>>(
                      streamValue: _controller.filteredPartnersStreamValue,
                      builder: (context, partners) {
                        return StreamValueBuilder<bool>(
                          streamValue: _controller.hasLoadedStreamValue,
                          builder: (context, hasLoaded) {
                            return StreamValueBuilder<DiscoveryFilterCatalog>(
                              streamValue:
                                  _controller.discoveryFilterCatalogStreamValue,
                              builder: (context, catalog) {
                                return StreamValueBuilder<
                                    DiscoveryFilterSelection>(
                                  streamValue: _controller
                                      .discoveryFilterSelectionStreamValue,
                                  builder: (context, filterSelection) {
                                    final hasCanonicalFilters =
                                        catalog.filters.isNotEmpty;
                                    final showDiscoveryHeader =
                                        !isSearching && hasLoaded;
                                    final showFilterPanel =
                                        showDiscoveryHeader &&
                                            hasCanonicalFilters;
                                    final showDefaultSections =
                                        showSections && filterSelection.isEmpty;
                                    final emptyLabel = showDefaultSections
                                        ? 'Nenhum perfil disponível no momento.'
                                        : 'Nenhum resultado para os filtros.';
                                    return CustomScrollView(
                                      controller: _controller.scrollController,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      slivers: [
                                        if (showFilterPanel)
                                          SliverToBoxAdapter(
                                            child: Offstage(
                                              offstage: true,
                                              child: SizeReportingWidget(
                                                onSizeChanged:
                                                    _updateFilterPanelExtent,
                                                child:
                                                    _buildCanonicalDiscoveryFilters(
                                                  context,
                                                  catalog: catalog,
                                                  selection: filterSelection,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (showDefaultSections)
                                          SliverToBoxAdapter(
                                            child: StreamValueBuilder<
                                                List<EventModel>?>(
                                              streamValue: _controller
                                                  .liveNowEventsStreamValue,
                                              builder: (context, liveNow) {
                                                return DiscoveryLiveNowSection(
                                                  items: liveNow ??
                                                      const <EventModel>[],
                                                  onTap: (event) =>
                                                      context.router.push(
                                                    ImmersiveEventDetailRoute(
                                                      eventSlug: event.slug,
                                                      occurrenceId: event
                                                          .selectedOccurrenceId,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        if (showDefaultSections)
                                          SliverToBoxAdapter(
                                            child: StreamValueBuilder<
                                                List<AccountProfileModel>>(
                                              streamValue:
                                                  _controller.nearbyStreamValue,
                                              builder: (context, nearby) {
                                                return DiscoveryNearbyRow(
                                                  items: nearby,
                                                  onTap: (partner) {
                                                    if (!partner
                                                        .canOpenPublicDetail) {
                                                      return;
                                                    }
                                                    _openPartnerDetail(
                                                      context,
                                                      partner,
                                                    );
                                                  },
                                                  resolvedVisualForItem: _controller
                                                      .resolvedVisualForAccountProfile,
                                                );
                                              },
                                            ),
                                          ),
                                        if (showDiscoveryHeader)
                                          SliverPersistentHeader(
                                            pinned: true,
                                            delegate:
                                                DiscoveryFilterHeaderDelegate(
                                              extent: _headerCollapsedExtent,
                                              title: 'Descubra',
                                              action: IconButton(
                                                tooltip: 'Buscar perfis',
                                                icon: const Icon(Icons.search),
                                                onPressed:
                                                    _controller.toggleSearch,
                                              ),
                                            ),
                                          ),
                                        if (showFilterPanel)
                                          SliverPersistentHeader(
                                            pinned: true,
                                            delegate:
                                                _DiscoveryStickyPanelDelegate(
                                              extent: _filterPanelExtent,
                                              child:
                                                  _buildCanonicalDiscoveryFilters(
                                                context,
                                                catalog: catalog,
                                                selection: filterSelection,
                                              ),
                                            ),
                                          ),
                                        SliverToBoxAdapter(
                                          child: StreamValueBuilder<bool>(
                                            streamValue: _controller
                                                .isRefreshingStreamValue,
                                            builder: (context, isRefreshing) {
                                              if (!isRefreshing) {
                                                return const SizedBox.shrink();
                                              }
                                              return const Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: LinearProgressIndicator(
                                                  minHeight: 2,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        if (partners.isEmpty)
                                          SliverToBoxAdapter(
                                            child: Builder(
                                              builder: (context) {
                                                if (!hasLoaded) {
                                                  return const Padding(
                                                    padding:
                                                        EdgeInsets.all(24.0),
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  );
                                                }
                                                if (isSearching) {
                                                  return _DiscoverySearchEmptyState(
                                                    hasQuery:
                                                        trimmedQuery.isNotEmpty,
                                                  );
                                                }
                                                return Padding(
                                                  padding: const EdgeInsets.all(
                                                      24.0),
                                                  child: Center(
                                                    child: Text(emptyLabel),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        else
                                          SliverPadding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 8, 16, 32),
                                            sliver: DiscoveryPartnerGrid(
                                              partners: partners,
                                              favorites: favorites,
                                              isFavoritable:
                                                  _controller.isFavoritable,
                                              onFavoriteTap: (partnerId) {
                                                if (partners.isEmpty) {
                                                  return;
                                                }
                                                final partner =
                                                    partners.firstWhere(
                                                  (item) =>
                                                      item.id == partnerId,
                                                  orElse: () => partners.first,
                                                );
                                                if (_controller.isFavoritable(
                                                  partner,
                                                )) {
                                                  _handleFavoriteTap(partner);
                                                }
                                              },
                                              onPartnerTap: (partner) =>
                                                  partner.canOpenPublicDetail
                                                      ? _openPartnerDetail(
                                                          context,
                                                          partner,
                                                        )
                                                      : null,
                                              resolvedVisualForPartner: _controller
                                                  .resolvedVisualForAccountProfile,
                                            ),
                                          ),
                                        SliverToBoxAdapter(
                                          child: StreamValueBuilder<bool>(
                                            streamValue: _controller
                                                .isPageLoadingStreamValue,
                                            builder: (context, isPageLoading) {
                                              if (!isPageLoading) {
                                                return const SizedBox.shrink();
                                              }
                                              return const Padding(
                                                padding: EdgeInsets.fromLTRB(
                                                  0,
                                                  0,
                                                  0,
                                                  24,
                                                ),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPendingIntent();
  }

  void _checkPendingIntent() {
    if (widget.isWebRuntime) {
      return;
    }
    final redirectPath =
        buildRedirectPathFromRouteMatch(context.routeData.route);
    final action = AuthWallTelemetry.consumePendingAction(redirectPath);
    if (action != null && action.actionType == AuthWallActionType.favorite) {
      final partnerId = action.payload?['partnerId'] as String?;
      if (partnerId != null) {
        _controller.toggleFavorite(partnerId);
      }
    }
  }

  void _handleFavoriteTap(AccountProfileModel partner) {
    final redirectPath = _partnerDetailRedirectPath(partner);
    final outcome = _controller.toggleFavorite(partner.id);
    if (outcome != FavoriteToggleOutcome.requiresAuthentication) {
      return;
    }
    unawaited(
      AccountProfileFavoriteAuthGate.handleRequiredAuthentication(
        context: context,
        accountProfileId: partner.id,
        redirectPath: redirectPath,
        isWebRuntime: widget.isWebRuntime,
      ),
    );
  }

  Future<void> _openPartnerDetail(
    BuildContext context,
    AccountProfileModel partner,
  ) async {
    if (!partner.canOpenPublicDetail) {
      return;
    }
    final publicDetailPath = partner.publicDetailPath?.trim();
    if (publicDetailPath != null && publicDetailPath.isNotEmpty) {
      await context.router.pushPath(publicDetailPath);
    }
  }

  String _partnerDetailRedirectPath(AccountProfileModel partner) {
    if (!partner.canOpenPublicDetail) {
      return buildRedirectPathFromRouteMatch(context.routeData.route);
    }
    final publicDetailPath = partner.publicDetailPath?.trim();
    if (publicDetailPath != null && publicDetailPath.isNotEmpty) {
      return publicDetailPath;
    }
    return buildRedirectPathFromRouteMatch(context.routeData.route);
  }

  Widget _buildBrandAppBarTitle() {
    final appData = _controller.appData;
    if (appData == null) {
      return const Text('Descobrir');
    }
    return MainLogo(
      appData: appData,
      width: 128,
      height: 34,
    );
  }

  Widget _buildCanonicalDiscoveryFilters(
    BuildContext context, {
    required DiscoveryFilterCatalog catalog,
    required DiscoveryFilterSelection selection,
  }) {
    return StreamValueBuilder<bool>(
      streamValue: _controller.isRefreshingStreamValue,
      builder: (context, isRefreshing) {
        return StreamValueBuilder<bool>(
          streamValue: _controller.isDiscoveryFilterCatalogLoadingStreamValue,
          builder: (context, isCatalogLoading) {
            return Semantics(
              container: true,
              label: 'Painel de filtros de perfis',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: DiscoveryFilterBar(
                  catalog: catalog,
                  selection: selection,
                  policy: _controller.discoveryFilterPolicy,
                  isLoading: isRefreshing || isCatalogLoading,
                  iconBuilder: buildDiscoveryFilterVisualIcon,
                  onSelectionChanged: _controller.setDiscoveryFilterSelection,
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateFilterPanelExtent(Size size) {
    final nextExtent =
        size.height <= 0 ? _defaultFilterPanelExtent : size.height;
    if ((nextExtent - _filterPanelExtent).abs() < 0.5 || !mounted) {
      return;
    }
    setState(() {
      _filterPanelExtent = nextExtent;
    });
  }
}

class _DiscoveryStickyPanelDelegate extends SliverPersistentHeaderDelegate {
  _DiscoveryStickyPanelDelegate({
    required this.extent,
    required this.child,
  });

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox.expand(
        child: ClipRect(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DiscoveryStickyPanelDelegate oldDelegate) {
    return extent != oldDelegate.extent || child != oldDelegate.child;
  }
}

class _DiscoverySearchEmptyState extends StatelessWidget {
  const _DiscoverySearchEmptyState({
    required this.hasQuery,
  });

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final title =
        hasQuery ? 'Nada encontrado ainda' : 'Nada para mostrar ainda';
    final description = hasQuery
        ? 'Não encontramos resultados para sua busca. Tente termos mais simples ou diferentes.'
        : 'Sem filtros ativos, essa busca deve listar todos os perfis disponíveis.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(
                Icons.search_off_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

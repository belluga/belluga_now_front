import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_filter_chips.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_filter_header_delegate.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_live_now_section.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_nearby_row.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_partner_grid.dart';
import 'package:belluga_now/presentation/shared/widgets/app_promotion_dialog.dart';
import 'package:belluga_now/presentation/shared/widgets/main_logo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final DiscoveryScreenController _controller =
      GetIt.I.get<DiscoveryScreenController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
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
              return IconButton(
                icon: Icon(isSearching ? Icons.close : Icons.search),
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
                final emptyLabel = showSections
                    ? 'Nenhum perfil disponível no momento.'
                    : 'Nenhum resultado para os filtros.';
                return StreamValueBuilder<Set<String>>(
                  streamValue: _controller.favoriteIdsStream,
                  builder: (context, favorites) {
                    return StreamValueBuilder<List<AccountProfileModel>>(
                      streamValue: _controller.filteredPartnersStreamValue,
                      builder: (context, partners) {
                        return StreamValueBuilder<bool>(
                          streamValue: _controller.hasLoadedStreamValue,
                          builder: (context, hasLoaded) {
                            return StreamValueBuilder<List<String>>(
                              streamValue:
                                  _controller.availableTypesStreamValue,
                              builder: (context, availableTypes) {
                                final showDiscoveryFilters = !isSearching &&
                                    hasLoaded &&
                                    availableTypes.isNotEmpty;
                                return CustomScrollView(
                                  controller: _controller.scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  slivers: [
                                    if (showSections)
                                      SliverToBoxAdapter(
                                        child: StreamValueBuilder<
                                            List<EventModel>>(
                                          streamValue: _controller
                                              .liveNowEventsStreamValue,
                                          builder: (context, liveNow) {
                                            return DiscoveryLiveNowSection(
                                              items: liveNow,
                                              onTap: (event) =>
                                                  context.router.push(
                                                ImmersiveEventDetailRoute(
                                                  eventSlug: event.slug,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    if (showSections)
                                      SliverToBoxAdapter(
                                        child: StreamValueBuilder<
                                            List<AccountProfileModel>>(
                                          streamValue:
                                              _controller.nearbyStreamValue,
                                          builder: (context, nearby) {
                                            return DiscoveryNearbyRow(
                                              items: nearby,
                                              onTap: (partner) =>
                                                  context.router.push(
                                                PartnerDetailRoute(
                                                    slug: partner.slug),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    if (showDiscoveryFilters)
                                      SliverPersistentHeader(
                                        pinned: true,
                                        delegate: DiscoveryFilterHeaderDelegate(
                                          extent: 122,
                                          title: 'Descubra',
                                          filterBuilder: () =>
                                              StreamValueBuilder<String?>(
                                            streamValue: _controller
                                                .selectedTypeFilterStreamValue,
                                            builder: (context, selectedType) {
                                              return DiscoveryFilterChips(
                                                selectedType: selectedType,
                                                availableTypes: availableTypes,
                                                onSelectType:
                                                    _controller.setTypeFilter,
                                                labelForType: _controller
                                                    .labelForAccountProfileType,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    SliverToBoxAdapter(
                                      child: StreamValueBuilder<bool>(
                                        streamValue:
                                            _controller.isRefreshingStreamValue,
                                        builder: (context, isRefreshing) {
                                          if (!isRefreshing) {
                                            return const SizedBox.shrink();
                                          }
                                          return const Padding(
                                            padding: EdgeInsets.only(bottom: 8),
                                            child: LinearProgressIndicator(
                                                minHeight: 2),
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
                                                padding: EdgeInsets.all(24.0),
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
                                              padding:
                                                  const EdgeInsets.all(24.0),
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
                                            if (partners.isEmpty) return;
                                            final partner = partners.firstWhere(
                                              (item) => item.id == partnerId,
                                              orElse: () => partners.first,
                                            );
                                            if (_controller
                                                .isFavoritable(partner)) {
                                              _handleFavoriteTap(partner);
                                            }
                                          },
                                          onPartnerTap: (partner) =>
                                              context.router.push(
                                            PartnerDetailRoute(
                                                slug: partner.slug),
                                          ),
                                          typeLabelForPartner: (partner) =>
                                              _controller
                                                  .labelForAccountProfileType(
                                            partner.type,
                                          ),
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
                                                0, 0, 0, 24),
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPendingIntent();
  }

  void _checkPendingIntent() {
    final redirectPath =
        buildRedirectPathFromRouteMatch(context.routeData.route);
    final action = AuthWallTelemetry.consumePendingAction(redirectPath);
    if (action != null && action.actionType == AuthWallActionType.favorite) {
      final partnerId = action.payload?['partnerId'] as String?;
      if (partnerId != null) {
        // Find the partner in the list. Wait, _controller.toggleFavorite just takes ID!
        // We can just call it with the partnerId. But the method takes AccountProfileModel.
        // Oh, wait, the controller method takes ID! But _handleFavoriteTap takes AccountProfileModel.
        // Let's call controller directly.
        _controller.toggleFavorite(partnerId);
      }
    }
  }

  void _handleFavoriteTap(AccountProfileModel partner) {
    final redirectPath =
        buildRedirectPathFromRouteMatch(context.routeData.route);
    if (kIsWeb) {
      AuthWallTelemetry.trackTriggered(
        actionType: AuthWallActionType.favorite,
        redirectPath: redirectPath,
        payload: {'partnerId': partner.id},
      );
      AppPromotionDialog.show(
        context,
        redirectPath: redirectPath,
        shareCode: resolveWebPromotionShareCode(
          redirectPath: redirectPath,
        ),
      );
      return;
    }

    final outcome = _controller.toggleFavorite(partner.id);
    if (outcome != FavoriteToggleOutcome.requiresAuthentication) {
      return;
    }
    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.favorite,
      redirectPath: redirectPath,
      payload: {'partnerId': partner.id},
    );
    final encodedRedirect = Uri.encodeQueryComponent(redirectPath);
    context.router.replacePath('/auth/login?redirect=$encodedRedirect');
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

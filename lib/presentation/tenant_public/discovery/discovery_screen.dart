import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_partner_card.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_curator_content_section.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_filter_chips.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_filter_header_delegate.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/widgets/discovery_partner_grid.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/carousel_section.dart';
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
                : const Text('Descobrir');
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
            return StreamValueBuilder<bool>(
              streamValue: _controller.isSearchingStreamValue,
              builder: (context, isSearching) {
                return StreamValueBuilder<String?>(
                  streamValue: _controller.selectedTypeFilterStreamValue,
                  builder: (context, selectedType) {
                    return StreamValueBuilder<String>(
                      streamValue: _controller.searchQueryStreamValue,
                      builder: (context, query) {
                        final showSections = !isSearching &&
                            selectedType == null &&
                            query.isEmpty;
                        final emptyLabel = showSections
                            ? 'Nenhum perfil disponível no momento.'
                            : 'Nenhum resultado para os filtros.';
                        return StreamValueBuilder<Set<String>>(
                          streamValue: _controller.favoriteIdsStream,
                          builder: (context, favorites) {
                            return StreamValueBuilder<List<AccountProfileModel>>(
                              streamValue:
                                  _controller.filteredPartnersStreamValue,
                              builder: (context, partners) {
                                return CustomScrollView(
                                  slivers: [
                                    if (showSections) ...[
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: StreamValueBuilder<
                                              List<AccountProfileModel>>(
                                            streamValue:
                                                _controller.liveNowStreamValue,
                                            builder: (context, liveNow) {
                                              return CarouselSection<
                                                  AccountProfileModel>(
                                                title: 'Tocando agora',
                                                items: liveNow,
                                                onSeeAll: () =>
                                                    _navigateToMap(context),
                                                headerPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 4),
                                                contentSpacing:
                                                    const EdgeInsets.only(
                                                        bottom: 16),
                                                cardBuilder: (partner) =>
                                                    DiscoveryPartnerCard(
                                                  partner: partner,
                                                  isFavoritable: _controller
                                                      .isPartnerFavoritable(
                                                          partner),
                                                  isFavorite: favorites
                                                      .contains(partner.id),
                                                  onFavoriteTap: () {
                                                    if (_controller
                                                        .isPartnerFavoritable(
                                                      partner,
                                                    )) {
                                                      _controller.toggleFavorite(
                                                        partner.id,
                                                      );
                                                    }
                                                  },
                                                  onTap: () =>
                                                      context.router.push(
                                                    PartnerDetailRoute(
                                                        slug: partner.slug),
                                                  ),
                                                  typeLabel: _controller
                                                      .labelForAccountProfileType(
                                                          partner.type),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: StreamValueBuilder<
                                              List<AccountProfileModel>>(
                                            streamValue:
                                                _controller.nearbyStreamValue,
                                            builder: (context, nearby) {
                                              return CarouselSection<
                                                  AccountProfileModel>(
                                                title: 'Perto de você',
                                                items: nearby,
                                                onSeeAll: () =>
                                                    _navigateToMap(context),
                                                headerPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 4),
                                                contentSpacing:
                                                    const EdgeInsets.only(
                                                        bottom: 16),
                                                cardBuilder: (partner) =>
                                                    DiscoveryPartnerCard(
                                                  partner: partner,
                                                  isFavoritable: _controller
                                                      .isPartnerFavoritable(
                                                          partner),
                                                  isFavorite: favorites
                                                      .contains(partner.id),
                                                  onFavoriteTap: () {
                                                    if (_controller
                                                        .isPartnerFavoritable(
                                                      partner,
                                                    )) {
                                                      _controller.toggleFavorite(
                                                        partner.id,
                                                      );
                                                    }
                                                  },
                                                  onTap: () =>
                                                      context.router.push(
                                                    PartnerDetailRoute(
                                                        slug: partner.slug),
                                                  ),
                                                  typeLabel: _controller
                                                      .labelForAccountProfileType(
                                                          partner.type),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      SliverToBoxAdapter(
                                        child: StreamValueBuilder(
                                          streamValue: _controller
                                              .curatorContentStreamValue,
                                          builder: (context, contents) {
                                            return DiscoveryCuratorContentSection(
                                              contents: contents,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                    SliverPersistentHeader(
                                      pinned: true,
                                      delegate: DiscoveryFilterHeaderDelegate(
                                        extent: 112,
                                        filterBuilder: () =>
                                            StreamValueBuilder<List<String>>(
                                          streamValue: _controller
                                              .availableTypesStreamValue,
                                          builder: (context, availableTypes) {
                                            return StreamValueBuilder<String?>(
                                              streamValue: _controller
                                                  .selectedTypeFilterStreamValue,
                                              builder:
                                                  (context, selectedType) {
                                                return DiscoveryFilterChips(
                                                  selectedType: selectedType,
                                                  availableTypes: availableTypes,
                                                  onSelectType:
                                                      _controller.setTypeFilter,
                                                  labelForType: _controller
                                                      .labelForAccountProfileType,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    if (partners.isEmpty)
                                      SliverToBoxAdapter(
                                        child: StreamValueBuilder<bool>(
                                          streamValue:
                                              _controller.hasLoadedStreamValue,
                                          builder: (context, hasLoaded) {
                                            if (!hasLoaded) {
                                              return const Padding(
                                                padding: EdgeInsets.all(24.0),
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.all(24.0),
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
                                              _controller.isPartnerFavoritable,
                                          onFavoriteTap:
                                              (partnerId) {
                                            if (partners.isEmpty) return;
                                            final partner = partners.firstWhere(
                                              (item) => item.id == partnerId,
                                              orElse: () => partners.first,
                                            );
                                            if (_controller
                                                .isPartnerFavoritable(partner)) {
                                              _controller
                                                  .toggleFavorite(partnerId);
                                            }
                                          },
                                          onPartnerTap: (partner) =>
                                              context.router.push(
                                            PartnerDetailRoute(
                                                slug: partner.slug),
                                          ),
                                          typeLabelForPartner: (partner) =>
                                              _controller.labelForAccountProfileType(
                                                  partner.type),
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
        ),
      ),
    );
  }

  void _navigateToMap(BuildContext context) {
    context.router.push(const CityMapRoute());
  }
}

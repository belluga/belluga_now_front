import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/presentation/tenant/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_carousel.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_curator_content_section.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_filter_chips.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_filter_header_delegate.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_partner_grid.dart';
import 'package:belluga_now/presentation/tenant/widgets/stream_value_section.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _controller = GetIt.I.get<DiscoveryScreenController>();

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
                return StreamValueBuilder<PartnerType?>(
                  streamValue: _controller.selectedTypeFilterStreamValue,
                  builder: (context, selectedType) {
                    return StreamValueBuilder<String>(
                      streamValue: _controller.searchQueryStreamValue,
                      builder: (context, query) {
                        final showSections =
                            !isSearching && selectedType == null && query.isEmpty;
                        return StreamValueBuilder<Set<String>>(
                          streamValue: _controller.favoriteIdsStream,
                          builder: (context, favorites) {
                            return StreamValueBuilder<List<PartnerModel>>(
                              streamValue: _controller.filteredPartnersStreamValue,
                              builder: (context, partners) {
                                return CustomScrollView(
                                  slivers: [
                                    if (showSections) ...[
                                      SliverToBoxAdapter(
                                        child: StreamValueSection<PartnerModel>(
                                          title: 'Tocando agora',
                                          stream: _controller.liveNowStreamValue,
                                          onSeeAll: () => _navigateToMap(context),
                                          headerPadding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 4),
                                          contentSpacing:
                                              const EdgeInsets.only(bottom: 16),
                                          contentBuilder: (context, events) {
                                            return StreamValueBuilder<Set<String>>(
                                              streamValue:
                                                  _controller.favoriteIdsStream,
                                              builder: (context, favorites) {
                                                return DiscoveryCarousel(
                                                  partners: events,
                                                  favorites: favorites,
                                                  onFavoriteToggle:
                                                      _controller.toggleFavorite,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      SliverToBoxAdapter(
                                        child: StreamValueSection<PartnerModel>(
                                          title: 'Perto de você',
                                          stream: _controller.nearbyStreamValue,
                                          onSeeAll: () => _navigateToMap(context),
                                          headerPadding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 4),
                                          contentSpacing:
                                              const EdgeInsets.only(bottom: 16),
                                          contentBuilder: (context, events) {
                                            return StreamValueBuilder<Set<String>>(
                                              streamValue:
                                                  _controller.favoriteIdsStream,
                                              builder: (context, favorites) {
                                                return DiscoveryCarousel(
                                                  partners: events,
                                                  favorites: favorites,
                                                  onFavoriteToggle:
                                                      _controller.toggleFavorite,
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      SliverToBoxAdapter(
                                        child: StreamValueBuilder(
                                          streamValue:
                                              _controller.curatorContentStreamValue,
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
                                        filterBuilder: () => DiscoveryFilterChips(
                                          selectedTypeStream: _controller
                                              .selectedTypeFilterStreamValue,
                                          onSelectType: _controller.setTypeFilter,
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
                                                  child: CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                            return const Padding(
                                              padding: EdgeInsets.all(24.0),
                                              child: Center(
                                                child: Text(
                                                  'Nenhum resultado para os filtros.',
                                                ),
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
                                          onFavoriteTap:
                                              _controller.toggleFavorite,
                                          onPartnerTap: (partner) =>
                                              context.router.push(
                                            PartnerDetailRoute(slug: partner.slug),
                                          ),
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

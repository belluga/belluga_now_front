import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/presentation/tenant/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_carousel.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_partner_card.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/curator_content_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:auto_route/auto_route.dart';

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
  void dispose() {
    // Controller disposal handled by ModuleScope
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: StreamValueBuilder<bool>(
          streamValue: _controller.isLoadingStreamValue,
          builder: (context, isLoading) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildContent();
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      title: StreamValueBuilder<bool>(
        streamValue: _controller.isSearchingStreamValue,
        builder: (context, isSearching) {
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
    );
  }

  Widget _buildContent() {
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
                                child: _buildSection(
                                  title: 'Tocando agora',
                                  stream: _controller.liveNowStreamValue,
                                  onSeeAll: () {
                                    context.router.push(const CityMapRoute());
                                  },
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: _buildSection(
                                  title: 'Perto de você',
                                  stream: _controller.nearbyStreamValue,
                                  onSeeAll: () {
                                    context.router.push(const CityMapRoute());
                                  },
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: _buildCuratorContentSection(),
                              ),
                            ],
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _ChipsHeaderDelegate(
                                extent: 112,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 8),
                                      child: Row(
                                        children: [
                                          const Text(
                                            'Tudo',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 16),
                                      child: _buildFilterChips(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (partners.isEmpty)
                              SliverToBoxAdapter(
                                child: StreamValueBuilder<bool>(
                                  streamValue: _controller.hasLoadedStreamValue,
                                  builder: (context, hasLoaded) {
                                    if (!hasLoaded) {
                                      return const Padding(
                                        padding: EdgeInsets.all(24.0),
                                        child: Center(
                                            child:
                                                CircularProgressIndicator()),
                                      );
                                    }
                                    return const Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Center(
                                          child: Text(
                                              'Nenhum resultado para os filtros.')),
                                    );
                                  },
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 8, 16, 32),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final partner = partners[index];
                                      return _buildPartnerCard(
                                        partner,
                                        isFavorite:
                                            favorites.contains(partner.id),
                                      );
                                    },
                                    childCount: partners.length,
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
  }

  Widget _buildCuratorContentSection() {
    return StreamValueBuilder(
      streamValue: _controller.curatorContentStreamValue,
      builder: (context, contents) {
        if (contents.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SectionHeader(
                title: 'Veja isso (curadores)',
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final content = contents[index];
                  return SizedBox(
                    width: 220,
                    child: CuratorContentCard(content: content),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: contents.length,
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return StreamValueBuilder<PartnerType?>(
      streamValue: _controller.selectedTypeFilterStreamValue,
      builder: (context, selectedType) {
        final items = <_FilterChipData>[
          _FilterChipData(label: 'Todos', type: null),
          _FilterChipData(label: 'Artistas', type: PartnerType.artist),
          _FilterChipData(label: 'Locais', type: PartnerType.venue),
          _FilterChipData(
              label: 'Experiências', type: PartnerType.experienceProvider),
          _FilterChipData(label: 'Pessoas', type: PartnerType.influencer),
          _FilterChipData(label: 'Curadores', type: PartnerType.curator),
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item.label),
                      selected: selectedType == item.type,
                      onSelected: (_) => _controller.setTypeFilter(item.type),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required StreamValue<List<PartnerModel>> stream,
    VoidCallback? onSeeAll,
  }) {
    return StreamValueBuilder<Set<String>>(
      streamValue: _controller.favoriteIdsStream,
      builder: (context, favorites) {
        return StreamValueBuilder<List<PartnerModel>>(
          streamValue: stream,
          builder: (context, partners) {
            if (partners.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SectionHeader(
                    title: title,
                    onPressed: onSeeAll ?? () {},
                  ),
                ),
                const SizedBox(height: 4),
                DiscoveryCarousel(
                  partners: partners,
                  favorites: favorites,
                  onFavoriteToggle: _controller.toggleFavorite,
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPartnerCard(PartnerModel partner,
      {required bool isFavorite}) {
    return DiscoveryPartnerCard(
      partner: partner,
      isFavorite: isFavorite,
      onFavoriteTap: () => _controller.toggleFavorite(partner.id),
      onTap: () {
        context.router.push(PartnerDetailRoute(slug: partner.slug));
      },
    );
  }
}

class _FilterChipData {
  _FilterChipData({required this.label, required this.type});
  final String label;
  final PartnerType? type;
}

class _ChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ChipsHeaderDelegate({
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: extent,
      child: SafeArea(
        top: false,
        bottom: false,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

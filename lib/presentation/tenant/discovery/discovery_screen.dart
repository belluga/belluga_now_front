import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/partners/partner_model.dart';
import 'package:belluga_now/presentation/tenant/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/discovery/widgets/discovery_partner_card.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:auto_route/auto_route.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _controller = GetIt.I.get<DiscoveryScreenController>();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Controller disposal handled by ModuleScope
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descobrir'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar artistas, locais...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _controller.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  onChanged: _controller.setSearchQuery,
                ),
              ),
              // Category tabs
              StreamValueBuilder<PartnerType?>(
                streamValue: _controller.selectedTypeFilterStreamValue,
                builder: (context, selectedType) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'Todos',
                          isSelected: selectedType == null,
                          onTap: () => _controller.setTypeFilter(null),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Artistas',
                          isSelected: selectedType == PartnerType.artist,
                          onTap: () =>
                              _controller.setTypeFilter(PartnerType.artist),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Locais',
                          isSelected: selectedType == PartnerType.venue,
                          onTap: () =>
                              _controller.setTypeFilter(PartnerType.venue),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Experiências',
                          isSelected:
                              selectedType == PartnerType.experienceProvider,
                          onTap: () => _controller
                              .setTypeFilter(PartnerType.experienceProvider),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Influenciadores',
                          isSelected: selectedType == PartnerType.influencer,
                          onTap: () =>
                              _controller.setTypeFilter(PartnerType.influencer),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Curadores',
                          isSelected: selectedType == PartnerType.curator,
                          onTap: () =>
                              _controller.setTypeFilter(PartnerType.curator),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: StreamValueBuilder<bool>(
        streamValue: _controller.isLoadingStreamValue,
        builder: (context, isLoading) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamValueBuilder<List<PartnerModel>>(
            streamValue: _controller.filteredPartnersStreamValue,
            builder: (context, partners) {
              if (partners.isEmpty) {
                return const Center(
                  child: Text('Nenhum parceiro encontrado'),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: partners.length,
                itemBuilder: (context, index) {
                  final partner = partners[index];
                  return _buildPartnerCard(partner);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor:
            isSelected ? colorScheme.primaryContainer : colorScheme.surface,
        labelStyle: TextStyle(
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPartnerCard(PartnerModel partner) {
    final isFav = _controller.isFavorite(partner.id);

    return DiscoveryPartnerCard(
      partner: partner,
      isFavorite: isFav,
      onFavoriteTap: () {
        setState(() {
          _controller.toggleFavorite(partner.id);
        });
      },
      onTap: () {
        context.router.push(PartnerDetailRoute(slug: partner.slug));
      },
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/mercado_screen/controllers/mercado_controller.dart';
import 'package:belluga_now/presentation/tenant/mercado/models/mercado_producer.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class MercadoScreen extends StatefulWidget {
  const MercadoScreen({super.key});

  @override
  State<MercadoScreen> createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  late final _controller = GetIt.I.get<MercadoController>();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.onDispose();
    super.dispose();
  }

  void _handleClearSearch() {
    _controller.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado'),
      ),
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 2),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SearchBar(
                controller: _controller.searchTextController,
                hintText: 'Buscar por produtor ou categoria...',
                leading: const Icon(Icons.search),
                trailing: [
                  StreamValueBuilder<String?>(
                    streamValue: _controller.searchTermStreamValue,
                    onNullWidget: const SizedBox.shrink(),
                    builder: (context, term) {
                      if (term == null || term.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Limpar pesquisa',
                        onPressed: _handleClearSearch,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamValueBuilder<List<MercadoCategory>>(
                  streamValue: _controller.categoriesStreamValue,
                  builder: (context, categories) {
                    return StreamValueBuilder<Set<String>>(
                      streamValue: _controller.selectedCategoriesStreamValue,
                      builder: (context, selected) {
                        if (categories.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final isSelected = selected.contains(category.id);
                            return FilterChip(
                              label: Text(category.label),
                              avatar: Icon(
                                category.icon,
                                size: 18,
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  _controller.toggleCategory(category.id),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          StreamValueBuilder<List<MercadoProducer>>(
            streamValue: _controller.filteredProducersStreamValue,
            builder: (context, producers) {
              if (producers.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 64,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum produtor encontrado',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tente ajustar sua pesquisa ou selecionar outra categoria.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                sliver: SliverList.separated(
                  itemCount: producers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final producer = producers[index];
                    return _ProducerCard(
                      producer: producer,
                      onTap: () => _openProducer(producer),
                      categoryResolver: _controller.categoryById,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openProducer(MercadoProducer producer) {
    context.router.push(ProducerStoreRoute(producer: producer));
  }
}

class _ProducerCard extends StatelessWidget {
  const _ProducerCard({
    required this.producer,
    required this.onTap,
    required this.categoryResolver,
  });

  final MercadoProducer producer;
  final VoidCallback onTap;
  final MercadoCategory? Function(String) categoryResolver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryIcons = producer.categories
        .map(categoryResolver)
        .whereType<MercadoCategory>()
        .map((category) => category.icon)
        .toList(growable: false);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(producer.logoImageUrl),
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                    onBackgroundImageError: (_, __) {},
                    child: producer.logoImageUrl.isEmpty
                        ? Text(
                            producer.name.characters.first.toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producer.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          producer.tagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                producer.address,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: categoryIcons
                    .map(
                      (icon) => Icon(
                        icon,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

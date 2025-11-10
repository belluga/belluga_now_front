import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/poi_category_theme.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class PoiDetailDeck extends StatefulWidget {
  const PoiDetailDeck({super.key});

  @override
  State<PoiDetailDeck> createState() => _PoiDetailDeckState();
}

class _PoiDetailDeckState extends State<PoiDetailDeck> {
  final _controller = GetIt.I.get<MapScreenController>();
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _pageIndex = 0;
  PoiFilterMode? _lastFilterMode;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return StreamValueBuilder<PoiFilterMode>(
      streamValue: _controller.filterModeStreamValue,
      builder: (_, mode) {
        if (_lastFilterMode != mode) {
          _lastFilterMode = mode;
          if (mode != PoiFilterMode.none) {
            _resetCarousel();
          }
        }
        if (mode == PoiFilterMode.none && _pageIndex != 0) {
          _resetCarousel();
        }
        if (mode != PoiFilterMode.none) {
          return StreamValueBuilder<List<CityPoiModel>>(
            streamValue: _controller.filteredPoisStreamValue,
            builder: (_, filtered) {
              if (filtered.isEmpty) {
                return const SizedBox.shrink();
              }
              final clampedIndex =
                  _pageIndex.clamp(0, filtered.length - 1).toInt();
              if (clampedIndex != _pageIndex &&
                  _pageController.hasClients &&
                  mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_pageController.hasClients) return;
                  _pageController.jumpToPage(0);
                });
                _pageIndex = clampedIndex;
              }
              return _FilteredDeck(
                pois: filtered,
                controller: _controller,
                colorScheme: scheme,
                pageController: _pageController,
                onChanged: (index) {
                  setState(() => _pageIndex = index);
                  _controller.selectPoi(filtered[index]);
                },
              );
            },
          );
        }

        return StreamValueBuilder<CityPoiModel?>(
          streamValue: _controller.selectedPoiStreamValue,
          onNullWidget: const SizedBox.shrink(),
          builder: (_, poi) => _SinglePoiCard(
            poi: poi!,
            colorScheme: scheme,
          ),
        );
      },
    );
  }

  void _resetCarousel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_pageIndex != 0) {
        setState(() => _pageIndex = 0);
      }
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    });
  }
}

class _FilteredDeck extends StatelessWidget {
  const _FilteredDeck({
    required this.pois,
    required this.controller,
    required this.colorScheme,
    required this.pageController,
    required this.onChanged,
  });

  final List<CityPoiModel> pois;
  final MapScreenController controller;
  final ColorScheme colorScheme;
  final PageController pageController;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _iconForFilterMode(controller.filterModeStreamValue.value),
              color: _accentColorForFilter(
                controller.filterModeStreamValue.value,
                colorScheme,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _titleForFilterMode(controller.filterModeStreamValue.value),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: pageController,
            itemCount: pois.length,
            onPageChanged: onChanged,
            itemBuilder: (_, index) {
              final poi = pois[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == pois.length - 1 ? 0 : 12,
                ),
                child: _PoiCard(
                  poi: poi,
                  colorScheme: colorScheme,
                  onPrimaryAction: () => controller.selectPoi(poi),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        _CarouselIndicators(
          length: pois.length,
          controller: pageController,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  String _titleForFilterMode(PoiFilterMode mode) {
    switch (mode) {
      case PoiFilterMode.events:
        return 'Eventos em destaque';
      case PoiFilterMode.restaurants:
        return 'Restaurantes selecionados';
      case PoiFilterMode.beaches:
        return 'Praias em foco';
      case PoiFilterMode.lodging:
        return 'Hospedagens próximas';
      case PoiFilterMode.none:
        return 'Pontos selecionados';
    }
  }

  IconData _iconForFilterMode(PoiFilterMode mode) {
    switch (mode) {
      case PoiFilterMode.events:
        return Icons.local_activity;
      case PoiFilterMode.restaurants:
        return Icons.restaurant;
      case PoiFilterMode.beaches:
        return Icons.beach_access;
      case PoiFilterMode.lodging:
        return Icons.hotel;
      case PoiFilterMode.none:
        return Icons.map;
    }
  }

  Color _accentColorForFilter(
    PoiFilterMode mode,
    ColorScheme scheme,
  ) {
    switch (mode) {
      case PoiFilterMode.events:
        return scheme.primary;
      case PoiFilterMode.restaurants:
        return categoryTheme(CityPoiCategory.restaurant, scheme).color;
      case PoiFilterMode.beaches:
        return categoryTheme(CityPoiCategory.beach, scheme).color;
      case PoiFilterMode.lodging:
        return categoryTheme(CityPoiCategory.lodging, scheme).color;
      case PoiFilterMode.none:
        return scheme.primary;
    }
  }
}

class _SinglePoiCard extends StatelessWidget {
  const _SinglePoiCard({
    required this.poi,
    required this.colorScheme,
  });

  final CityPoiModel poi;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return _PoiCard(
      poi: poi,
      colorScheme: colorScheme,
      onPrimaryAction: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Abrindo ${poi.name}')),
      ),
    );
  }
}

class _PoiCard extends StatelessWidget {
  const _PoiCard({
    required this.poi,
    required this.colorScheme,
    required this.onPrimaryAction,
  });

  final CityPoiModel poi;
  final ColorScheme colorScheme;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final tags = poi.tags.take(5).toList();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poi.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            poi.address,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 60),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPrimaryAction,
                  child: const Text('Ver detalhes'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Compartilhar',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Compartilhar ${poi.name}')),
                ),
                icon: const Icon(Icons.share_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarouselIndicators extends StatefulWidget {
  const _CarouselIndicators({
    required this.length,
    required this.controller,
    required this.colorScheme,
  });

  final int length;
  final PageController controller;
  final ColorScheme colorScheme;

  @override
  State<_CarouselIndicators> createState() => _CarouselIndicatorsState();
}

class _CarouselIndicatorsState extends State<_CarouselIndicators> {
  int _index = 0;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (!widget.controller.hasClients) return;
      final page =
          widget.controller.page ?? widget.controller.initialPage.toDouble();
      final nextIndex = page.round().clamp(0, widget.length - 1);
      if (_index != nextIndex && mounted) {
        setState(() => _index = nextIndex);
      }
    };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (i) {
        final isActive = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 18 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? widget.colorScheme.primary
                : widget.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/manual_route_stubs.dart';
import 'package:belluga_now/domain/experiences/experience_model.dart';
import 'package:belluga_now/presentation/tenant/screens/experiences/controller/experiences_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/experiences/widgets/experience_card.dart';
import 'package:belluga_now/presentation/tenant/widgets/belluga_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class ExperiencesScreen extends StatefulWidget {
  const ExperiencesScreen({super.key});

  @override
  State<ExperiencesScreen> createState() => _ExperiencesScreenState();
}

class _ExperiencesScreenState extends State<ExperiencesScreen> {
  late final ExperiencesController _controller =
      GetIt.I.get<ExperiencesController>();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiencias'),
      ),
      bottomNavigationBar: const BellugaBottomNavigationBar(currentIndex: 3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar por experiencia ou categoria...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              StreamValueBuilder<String?>(
                streamValue: _controller.selectedCategoryStreamValue,
                onNullWidget: _CategoryChips(
                  categories: const [],
                  onCategorySelected: null,
                ),
                builder: (context, selectedCategory) {
                  final categories = _controller.categories.toList()
                    ..sort();
                  return _CategoryChips(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    onCategorySelected: _controller.selectCategory,
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamValueBuilder<List<ExperienceModel>>(
                  streamValue: _controller.experiencesStreamValue,
                  builder: (context, experiences) {
                    if (experiences.isEmpty) {
                      return const _EmptyState();
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            constraints.maxWidth > 600 ? 3 : 2;
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisExtent: 260,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: experiences.length,
                          itemBuilder: (context, index) {
                            final experience = experiences[index];
                            return ExperienceCard(
                              experience: experience,
                              onTap: () => _openDetails(experience),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Text(
                'Conteudo mockado para validacao visual.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    if (value.isEmpty) {
      _controller.clearFilters();
    } else {
      _controller.updateSearchQuery(value);
    }
  }

  void _openDetails(ExperienceModel experience) {
    context.router.push(
      ExperienceDetailRoute(experience: experience),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final void Function(String?)? onCategorySelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todos'),
              selected: selectedCategory == null,
              onSelected: (_) => onCategorySelected?.call(null),
            ),
          ),
          ...categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: category == selectedCategory,
                onSelected: (_) => onCategorySelected?.call(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.travel_explore,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhuma experiencia encontrada.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}


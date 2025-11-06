import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/experiences/experience_model.dart';
import 'package:belluga_now/presentation/tenant/experiences/screens/experiences_screen/controllers/experiences_controller.dart';
import 'package:belluga_now/presentation/tenant/experiences/screens/experiences_screen/widgets/experience_card.dart';
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
                controller: _controller.searchTextController,
                decoration: InputDecoration(
                  hintText: 'Buscar por experiencia ou categoria...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: StreamValueBuilder<String?>(
                    streamValue: _controller.searchTermStreamValue,
                    builder: (context, term) {
                      if (term == null || term.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Limpar pesquisa',
                        onPressed: _controller.clearFilters,
                      );
                    },
                  ),
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
                  final categories = _controller.categories.toList()..sort();
                  return _CategoryChips(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    onCategorySelected: _controller.selectCategory,
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamValueBuilder<Set<String>>(
                streamValue: _controller.selectedTagsStreamValue,
                builder: (context, selectedTags) {
                  final tags = _controller.tags.toList()..sort();
                  if (tags.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final currentSelection = selectedTags ?? <String>{};
                  return _TagChips(
                    tags: tags,
                    selectedTags: currentSelection,
                    onTagToggled: _controller.toggleTag,
                    onClearTags: _controller.clearTagFilters,
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

class _TagChips extends StatelessWidget {
  const _TagChips({
    required this.tags,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onClearTags,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final void Function(String tag) onTagToggled;
  final VoidCallback onClearTags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (selectedTags.isNotEmpty)
              FilterChip(
                label: const Text('Limpar tags'),
                selected: false,
                onSelected: (_) => onClearTags(),
              ),
            for (final tag in tags)
              FilterChip(
                label: Text(tag),
                selected: selectedTags.contains(tag),
                onSelected: (_) => onTagToggled(tag),
              ),
          ],
        ),
      ],
    );
  }
}

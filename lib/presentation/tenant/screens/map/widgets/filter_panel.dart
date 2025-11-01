import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_category_theme.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({super.key, required this.controller});

  final CityMapController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: mediaQuery.viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtros',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StreamValueBuilder<Set<CityPoiCategory>>(
                  streamValue: controller.selectedCategories,
                  builder: (context, categories) {
                    final hasCategories = categories?.isNotEmpty ?? false;
                    final hasTags =
                        controller.selectedTags.value?.isNotEmpty ?? false;
                    final hasFilters = hasCategories || hasTags;
                    return TextButton.icon(
                      onPressed: hasFilters
                          ? () {
                              controller.clearFilters();
                            }
                          : null,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpar'),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamValueBuilder<PoiFilterOptions?>(
              streamValue: controller.filterOptionsStreamValue,
              builder: (context, options) {
                if (options == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (controller.filtersLoadFailed) {
                  return _ErrorMessage(theme: theme);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamValueBuilder<Set<CityPoiCategory>>(
                      streamValue: controller.selectedCategories,
                      builder: (context, categories) {
                        final selected = categories ?? const <CityPoiCategory>{};
                        return _CategoryChips(
                          options: options,
                          selected: selected,
                          onToggle: controller.toggleCategory,
                        );
                      },
                    ),
                    StreamValueBuilder<Set<CityPoiCategory>>(
                      streamValue: controller.selectedCategories,
                      builder: (context, categories) {
                        final selected = categories ?? const <CityPoiCategory>{};
                        final availableTags =
                            options.tagsForCategories(selected).toList()
                              ..sort();
                        return StreamValueBuilder<Set<String>>(
                          streamValue: controller.selectedTags,
                          builder: (context, tags) {
                            return _TagSection(
                              availableTags: availableTags,
                              selectedTags: tags ?? const <String>{},
                              hasCategorySelection: selected.isNotEmpty,
                              onToggle: controller.toggleTag,
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  final PoiFilterOptions options;
  final Set<CityPoiCategory> selected;
  final ValueChanged<CityPoiCategory> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = options.sortedCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final categoryOption in categories)
              _CategoryChip(
                category: categoryOption.category,
                selected: selected.contains(categoryOption.category),
                onToggle: onToggle,
                scheme: scheme,
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onToggle,
    required this.scheme,
  });

  final CityPoiCategory category;
  final bool selected;
  final ValueChanged<CityPoiCategory> onToggle;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final themeData = categoryTheme(category, scheme);
    return FilterChip(
      label: Text(themeData.label),
      avatar: Icon(themeData.icon, size: 18, color: themeData.color),
      selected: selected,
      onSelected: (_) => onToggle(category),
      selectedColor: themeData.color.withOpacity(0.18),
      checkmarkColor: themeData.color,
      side: selected
          ? BorderSide(color: themeData.color, width: 1.4)
          : BorderSide(color: scheme.outlineVariant),
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.availableTags,
    required this.selectedTags,
    required this.hasCategorySelection,
    required this.onToggle,
  });

  final List<String> availableTags;
  final Set<String> selectedTags;
  final bool hasCategorySelection;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (!hasCategorySelection || availableTags.isEmpty) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Subcategorias',
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in availableTags)
              FilterChip(
                label: Text(_formatTag(tag)),
                selected: selectedTags.contains(tag),
                onSelected: (_) => onToggle(tag),
              ),
          ],
        ),
      ],
    );
  }

  String _formatTag(String value) {
    if (value.length <= 1) {
      return value.toUpperCase();
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Não foi possível carregar os filtros neste momento.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

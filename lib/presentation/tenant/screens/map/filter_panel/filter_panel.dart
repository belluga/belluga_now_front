import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/filter_panel/widgets/filter_category_chips.dart';
import 'package:belluga_now/presentation/tenant/screens/map/filter_panel/widgets/filter_error_message.dart';
import 'package:belluga_now/presentation/tenant/screens/map/filter_panel/widgets/filter_tag_section.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FilterPanel extends StatelessWidget {
  FilterPanel({super.key});

  final CityMapController _controller = GetIt.I.get<CityMapController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  'Filtros',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StreamValueBuilder<Set<CityPoiCategory>>(
                streamValue: _controller.selectedCategories,
                builder: (context, categories) {
                  final hasCategories = categories?.isNotEmpty ?? false;
                  final hasTags =
                      _controller.selectedTags.value?.isNotEmpty ?? false;
                  final hasFilters = hasCategories || hasTags;
                  return TextButton.icon(
                    onPressed: hasFilters ? _controller.clearFilters : null,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Limpar'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamValueBuilder<PoiFilterOptions?>(
            streamValue: _controller.filterOptionsStreamValue,
            builder: (context, options) {
              if (options == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }

              if (_controller.filtersLoadFailed) {
                return FilterErrorMessage(theme: theme);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamValueBuilder<Set<CityPoiCategory>>(
                    streamValue: _controller.selectedCategories,
                    builder: (context, categories) {
                      final selected = categories ?? const <CityPoiCategory>{};
                      return FilterCategoryChips(
                        options: options,
                        selected: selected,
                        onToggle: _controller.toggleCategory,
                      );
                    },
                  ),
                  StreamValueBuilder<Set<CityPoiCategory>>(
                    streamValue: _controller.selectedCategories,
                    builder: (context, categories) {
                      final selected = categories ?? const <CityPoiCategory>{};
                      final availableTags =
                          options.tagsForCategories(selected).toList()
                            ..sort();
                      return StreamValueBuilder<Set<String>>(
                        streamValue: _controller.selectedTags,
                        builder: (context, tags) {
                          return FilterTagSection(
                            availableTags: availableTags,
                            selectedTags: tags ?? const <String>{},
                            hasCategorySelection: selected.isNotEmpty,
                            onToggle: _controller.toggleTag,
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
    );
  }
}

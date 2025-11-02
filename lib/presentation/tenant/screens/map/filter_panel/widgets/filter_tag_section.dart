import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FilterTagSection extends StatelessWidget {
  const FilterTagSection({
    super.key,
    required this.options,
  });

  final PoiFilterOptions options;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I.get<CityMapController>();
    final textTheme = Theme.of(context).textTheme;

    return StreamValueBuilder<Set<CityPoiCategory>>(
      streamValue: controller.selectedCategories,
      builder: (context, categories) {
        final selectedCategories = categories ?? const <CityPoiCategory>{};
        final availableTags =
            options.tagsForCategories(selectedCategories).toList()..sort();
        if (selectedCategories.isEmpty || availableTags.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamValueBuilder<Set<String>>(
          streamValue: controller.selectedTags,
          builder: (context, tags) {
            final selectedTags = tags ?? const <String>{};
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
                        visualDensity: VisualDensity.compact,
                        selected: selectedTags.contains(tag),
                        onSelected: (_) => controller.toggleTag(tag),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTag(String value) {
    if (value.length <= 1) {
      return value.toUpperCase();
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}

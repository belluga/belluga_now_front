import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FilterTagSection extends StatefulWidget {
  const FilterTagSection({
    super.key,
    required this.options,
  }) : controller = null;

  @visibleForTesting
  const FilterTagSection.withController(
    this.controller, {
    super.key,
    required this.options,
  });

  final PoiFilterOptions options;
  final CityMapController? controller;

  @override
  State<FilterTagSection> createState() => _FilterTagSectionState();
}

class _FilterTagSectionState extends State<FilterTagSection> {
  CityMapController get _controller =>
      widget.controller ?? GetIt.I.get<CityMapController>();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return StreamValueBuilder<Set<CityPoiCategory>>(
      streamValue: _controller.selectedCategories,
      builder: (context, categories) {
        final selectedCategories = categories;
        final availableTags = widget.options
            .tagsForCategories(selectedCategories)
            .toList()
          ..sort();
        if (selectedCategories.isEmpty || availableTags.isEmpty) {
          return const SizedBox.shrink();
        }
        return StreamValueBuilder<Set<String>>(
          streamValue: _controller.selectedTags,
          builder: (context, tags) {
            final selectedTags = tags;
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
                        onSelected: (_) => _controller.toggleTag(tag),
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

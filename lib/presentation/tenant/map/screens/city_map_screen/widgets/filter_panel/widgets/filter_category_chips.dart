import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/filter_panel/widgets/filter_category_chip.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class FilterCategoryChips extends StatelessWidget {
  const FilterCategoryChips({
    super.key,
    required this.options,
  });

  final PoiFilterOptions options;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = GetIt.I.get<CityMapController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorias',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        StreamValueBuilder<Set<CityPoiCategory>>(
          streamValue: controller.selectedCategories,
          builder: (context, selectedCategories) {
            final selected = selectedCategories;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final categoryOption in options.categories)
                  FilterCategoryChip(
                    category: categoryOption.category,
                    isSelected: selected.contains(categoryOption.category),
                    scheme: scheme,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

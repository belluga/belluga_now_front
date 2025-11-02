import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant/screens/map/filter_panel/widgets/filter_category_chip.dart';
import 'package:flutter/material.dart';

class FilterCategoryChips extends StatelessWidget {
  const FilterCategoryChips({
    super.key,
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
            for (final categoryOption in options.categories)
              FilterCategoryChip(
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

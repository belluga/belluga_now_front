import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/poi_category_theme.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class FilterCategoryChip extends StatelessWidget {
  const FilterCategoryChip({
    super.key,
    required this.category,
    required this.scheme,
    required this.isSelected,
  });

  final CityPoiCategory category;
  final bool isSelected;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final controller = GetIt.I.get<CityMapController>();
    final themeData = categoryTheme(category, scheme);
    return FilterChip(
      label: Text(themeData.label),
      avatar: Icon(themeData.icon, size: 18, color: themeData.color),
      selected: isSelected,
      onSelected: (_) => controller.toggleCategory(category),
      selectedColor: themeData.color.withOpacity(0.18),
      checkmarkColor: themeData.color,
      side: isSelected
          ? BorderSide(color: themeData.color, width: 1.4)
          : BorderSide(color: scheme.outlineVariant),
    );
  }
}

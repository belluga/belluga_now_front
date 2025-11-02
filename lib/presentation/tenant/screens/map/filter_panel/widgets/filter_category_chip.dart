import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_category_theme.dart';
import 'package:flutter/material.dart';

class FilterCategoryChip extends StatelessWidget {
  const FilterCategoryChip({
    super.key,
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

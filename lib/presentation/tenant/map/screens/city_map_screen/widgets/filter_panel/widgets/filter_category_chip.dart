import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/controllers/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/city_map_screen/widgets/shared/poi_category_theme.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class FilterCategoryChip extends StatefulWidget {
  const FilterCategoryChip({
    super.key,
    required this.category,
    required this.scheme,
    required this.isSelected,
  }) : controller = null;

  @visibleForTesting
  const FilterCategoryChip.withController(
    this.controller, {
    super.key,
    required this.category,
    required this.scheme,
    required this.isSelected,
  });

  final CityPoiCategory category;
  final bool isSelected;
  final ColorScheme scheme;
  final CityMapController? controller;

  @override
  State<FilterCategoryChip> createState() => _FilterCategoryChipState();
}

class _FilterCategoryChipState extends State<FilterCategoryChip> {
  CityMapController get _controller =>
      widget.controller ?? GetIt.I.get<CityMapController>();

  @override
  Widget build(BuildContext context) {
    final themeData = categoryTheme(widget.category, widget.scheme);
    return FilterChip(
      label: Text(themeData.label),
      avatar: Icon(themeData.icon, size: 18, color: themeData.color),
      selected: widget.isSelected,
      onSelected: (_) => _controller.toggleCategory(widget.category),
      selectedColor: themeData.color.withValues(alpha: 0.18),
      checkmarkColor: themeData.color,
      side: widget.isSelected
          ? BorderSide(color: themeData.color, width: 1.4)
          : BorderSide(color: widget.scheme.outlineVariant),
    );
  }
}

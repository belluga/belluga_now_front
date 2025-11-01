import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant/screens/map/widgets/poi_category_theme.dart';
import 'package:flutter/material.dart';

class PoiMarker extends StatelessWidget {
  const PoiMarker({
    super.key,
    required this.poi,
    required this.isSelected,
  });

  final CityPoiModel poi;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = categoryTheme(poi.category, scheme);

    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isSelected ? 1.12 : 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.color.withOpacity(0.92),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.35 : 0.25),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            theme.icon,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

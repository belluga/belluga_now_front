import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:flutter/material.dart';

class CityPoiCategoryThemeData {
  const CityPoiCategoryThemeData({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}

CityPoiCategoryThemeData categoryTheme(
  CityPoiCategory category,
  ColorScheme scheme,
) {
  switch (category) {
    case CityPoiCategory.restaurant:
      return CityPoiCategoryThemeData(
        icon: Icons.restaurant,
        color: const Color(0xFFE15A3C),
        label: 'Restaurante',
      );
    case CityPoiCategory.health:
      return CityPoiCategoryThemeData(
        icon: Icons.local_hospital,
        color: const Color(0xFF2E7D32),
        label: 'Saúde',
      );
    case CityPoiCategory.monument:
      return CityPoiCategoryThemeData(
        icon: Icons.account_balance,
        color: const Color(0xFF3949AB),
        label: 'Ponto histórico',
      );
    case CityPoiCategory.church:
      return CityPoiCategoryThemeData(
        icon: Icons.church,
        color: const Color(0xFF6D4C41),
        label: 'Igreja',
      );
    case CityPoiCategory.culture:
      return CityPoiCategoryThemeData(
        icon: Icons.museum,
        color: const Color(0xFF8E24AA),
        label: 'Cultura',
      );
    case CityPoiCategory.nature:
      return CityPoiCategoryThemeData(
        icon: Icons.park,
        color: const Color(0xFF00897B),
        label: 'Natureza',
      );
  }
}

import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_marker.dart';
import 'package:free_map/free_map.dart';
import 'package:flutter/material.dart';

class PoiMarkerBuilder {
  const PoiMarkerBuilder();

  Marker build({
    required CityPoiModel poi,
    required bool isSelected,
    required VoidCallback onTap,
    required double size,
  }) {
    final point = LatLng(
      poi.coordinate.latitude,
      poi.coordinate.longitude,
    );

    final child = GestureDetector(
      onTap: onTap,
      child: PoiMarker(
        poi: poi,
        isSelected: isSelected,
      ),
    );

    return Marker(
      point: point,
      width: size,
      height: size,
      child: child,
    );
  }
}

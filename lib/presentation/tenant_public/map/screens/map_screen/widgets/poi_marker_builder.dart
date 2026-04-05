import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/projections/city_poi_visual.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_surface/belluga_map_surface_contract.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/poi_marker.dart';
import 'package:flutter/material.dart';

class PoiMarkerBuilder {
  const PoiMarkerBuilder();

  BellugaMapAnnotation build({
    required CityPoiModel poi,
    required bool isSelected,
    required VoidCallback onTap,
    required double size,
    CityPoiVisual? overrideVisual,
  }) {
    return BellugaMapAnnotation(
      id: poi.id,
      coordinate: poi.coordinate,
      width: size,
      height: size,
      child: PoiMarker(
        poi: poi,
        isSelected: isSelected,
        overrideVisual: overrideVisual,
      ),
      onTap: onTap,
    );
  }
}

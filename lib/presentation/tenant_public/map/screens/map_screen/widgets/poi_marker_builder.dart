import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/event_poi_model.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/shared/event_marker.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/widgets/shared/poi_marker.dart';
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
    final isEvent = poi is EventPoiModel;
    final point = LatLng(
      poi.coordinate.latitude,
      poi.coordinate.longitude,
    );

    final child = GestureDetector(
      onTap: onTap,
      child: isEvent
          ? EventMarker(
              event: poi.event,
              isSelected: isSelected,
            )
          : PoiMarker(
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

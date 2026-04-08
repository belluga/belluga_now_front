export 'package:belluga_now/application/map_surface/belluga_map_handle.dart';
export 'package:belluga_now/application/map_surface/belluga_map_handle_contract.dart';
export 'package:belluga_now/application/map_surface/belluga_map_interaction.dart';

import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:flutter/widgets.dart';

class BellugaMapAnnotation {
  const BellugaMapAnnotation({
    required this.id,
    required this.coordinate,
    required this.width,
    required this.height,
    required this.child,
    this.onTap,
  });

  final String id;
  final CityCoordinate coordinate;
  final double width;
  final double height;
  final Widget child;
  final VoidCallback? onTap;
}

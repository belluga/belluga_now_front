import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/map_bounds_delta_value.dart';
import 'package:belluga_now/domain/map/value_objects/map_region_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/map_region_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/map_zoom_value.dart';

class MapRegionDefinition {
  MapRegionDefinition({
    required this.idValue,
    required this.labelValue,
    required this.center,
    required this.zoomValue,
    MapBoundsDeltaValue? boundsDeltaValue,
  }) : boundsDeltaValue =
           boundsDeltaValue ?? (MapBoundsDeltaValue()..parse('0.08'));

  final MapRegionIdValue idValue;
  final MapRegionLabelValue labelValue;
  final CityCoordinate center;
  final MapZoomValue zoomValue;
  final MapBoundsDeltaValue boundsDeltaValue;

  String get id => idValue.value;

  String get label => labelValue.value;

  double get zoom => zoomValue.value;

  double get boundsDelta => boundsDeltaValue.value;
}

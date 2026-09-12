import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';

class PoiSceneResult {
  PoiSceneResult({
    required List<CityPoiModel> points,
    required this.isPartialValue,
  }) : points = List<CityPoiModel>.unmodifiable(points);

  final List<CityPoiModel> points;
  final PoiBooleanValue isPartialValue;
  bool get isPartial => isPartialValue.value;
}

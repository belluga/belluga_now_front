import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_positive_int_value.dart';

class PoiFilterPage {
  PoiFilterPage({
    required this.pageValue,
    required this.pageSizeValue,
    required this.hasMoreValue,
    required List<CityPoiModel> items,
  }) : items = List<CityPoiModel>.unmodifiable(items);

  final PoiPositiveIntValue pageValue;
  final PoiPositiveIntValue pageSizeValue;
  final PoiBooleanValue hasMoreValue;
  int get page => pageValue.value;
  int get pageSize => pageSizeValue.value;
  bool get hasMore => hasMoreValue.value;
  final List<CityPoiModel> items;
}

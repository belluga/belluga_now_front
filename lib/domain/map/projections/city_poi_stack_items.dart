import 'package:belluga_now/domain/map/projections/city_poi_model.dart';

class CityPoiStackItems {
  CityPoiStackItems() : _value = <CityPoiModel>[];

  final List<CityPoiModel> _value;

  List<CityPoiModel> get value => List<CityPoiModel>.unmodifiable(_value);

  void add(CityPoiModel item) {
    _value.add(item);
  }
}

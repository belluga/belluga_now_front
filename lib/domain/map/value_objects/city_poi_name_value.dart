import 'package:belluga_now/domain/value_objects/title_value.dart';

class CityPoiNameValue extends TitleValue {
  CityPoiNameValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 3,
  });
}

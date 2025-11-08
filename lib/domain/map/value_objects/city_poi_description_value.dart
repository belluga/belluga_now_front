import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class CityPoiDescriptionValue extends GenericStringValue {
  CityPoiDescriptionValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.minLenght = 3,
  });
}

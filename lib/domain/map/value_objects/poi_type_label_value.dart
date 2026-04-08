import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class PoiTypeLabelValue extends GenericStringValue {
  PoiTypeLabelValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.minLenght = 0,
  });
}

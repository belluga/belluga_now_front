import 'package:value_objects/domain/value_objects/generic_string_value.dart';

class DescriptionValue extends GenericStringValue {
  DescriptionValue({
    super.defaultValue = "",
    super.isRequired = false,
    super.minLenght = 10,
  });
}

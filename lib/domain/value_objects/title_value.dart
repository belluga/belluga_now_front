import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class TitleValue extends GenericStringValue {
  TitleValue({
    super.defaultValue = "",
    super.isRequired = false,
    super.minLenght = 5,
  });
}

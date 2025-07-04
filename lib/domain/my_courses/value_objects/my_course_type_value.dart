import 'package:value_objects/domain/value_objects/generic_string_value.dart';

class MyCourseTypeValue extends GenericStringValue {
  MyCourseTypeValue({
    super.defaultValue = "",
    super.isRequired = true,
    super.minLenght = 20,
  });
}

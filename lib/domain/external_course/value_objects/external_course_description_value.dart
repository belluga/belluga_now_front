import 'package:value_objects/domain/value_objects/generic_string_value.dart';

class ExternalCourseDescriptionValue extends GenericStringValue {
  ExternalCourseDescriptionValue({
    super.defaultValue = "",
    super.isRequired = false,
    super.minLenght = 10,
  });
}

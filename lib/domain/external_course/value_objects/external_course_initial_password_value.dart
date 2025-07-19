import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ExternalCourseInitialPasswordValue extends GenericStringValue {
  ExternalCourseInitialPasswordValue({
    super.defaultValue = "",
    super.isRequired = false,
    super.minLenght = 6,
  });
}

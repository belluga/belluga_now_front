import 'package:value_objects/domain/value_objects/generic_string_value.dart';

class ExternalCourseTitleValue extends GenericStringValue {
  ExternalCourseTitleValue({
    super.defaultValue = "",
    super.isRequired = false,
    super.minLenght = 5,
  });
}

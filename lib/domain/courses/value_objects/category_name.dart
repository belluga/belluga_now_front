import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class CategoryNameValue extends GenericStringValue {
  CategoryNameValue({
    super.defaultValue = "",
    super.isRequired = false,
    super.minLenght = 3,
  });
}

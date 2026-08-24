import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class EventOptionalTextValue extends GenericStringValue {
  EventOptionalTextValue({
    super.defaultValue = '',
    super.isRequired = false,
  });
}

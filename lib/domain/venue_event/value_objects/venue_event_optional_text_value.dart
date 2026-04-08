import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class VenueEventOptionalTextValue extends GenericStringValue {
  VenueEventOptionalTextValue({
    super.defaultValue = '',
    super.isRequired = false,
  });
}

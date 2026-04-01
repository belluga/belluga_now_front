import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class PartnerProjectionOptionalTextValue extends GenericStringValue {
  PartnerProjectionOptionalTextValue({
    super.defaultValue = '',
    super.isRequired = false,
  });
}

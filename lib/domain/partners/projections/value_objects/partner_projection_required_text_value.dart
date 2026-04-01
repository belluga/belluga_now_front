import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class PartnerProjectionRequiredTextValue extends GenericStringValue {
  PartnerProjectionRequiredTextValue({
    super.defaultValue = '',
    super.isRequired = true,
  });
}

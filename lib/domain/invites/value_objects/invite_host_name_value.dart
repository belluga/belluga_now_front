import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class InviteHostNameValue extends GenericStringValue {
  InviteHostNameValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 3,
  });
}

import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class InviteableReasonValue extends GenericStringValue {
  InviteableReasonValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 1,
  });
}

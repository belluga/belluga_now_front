import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class InviteAccountProfileIdValue extends GenericStringValue {
  InviteAccountProfileIdValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.minLenght = 1,
  });
}

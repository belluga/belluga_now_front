import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class InviteResolvedSenderDisplayNameValue extends GenericStringValue {
  InviteResolvedSenderDisplayNameValue({
    super.defaultValue = 'Alguém',
    super.isRequired = true,
    super.minLenght = 1,
  });
}

import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

/// Sender name from transport before the received-invite label is resolved.
class InviteSenderDisplayNameCandidateValue extends GenericStringValue {
  InviteSenderDisplayNameCandidateValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.minLenght = 1,
  });

  @override
  void validate(String? newValue) {
    if (newValue == null || newValue.isEmpty) return;
    super.validate(newValue);
  }
}

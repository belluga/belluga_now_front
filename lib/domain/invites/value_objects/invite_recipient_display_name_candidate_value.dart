import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

/// Backend display-name candidate before the invite composer applies local fallbacks.
class InviteRecipientDisplayNameCandidateValue extends GenericStringValue {
  InviteRecipientDisplayNameCandidateValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.minLenght = 1,
  });

  @override
  void validate(String? newValue) {
    if (newValue == null || newValue.isEmpty) {
      return;
    }
    super.validate(newValue);
  }
}

import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

/// Non-empty label after the invite composer resolves account/contact fallbacks.
class InviteRecipientResolvedDisplayLabelValue extends GenericStringValue {
  InviteRecipientResolvedDisplayLabelValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 1,
  });
}

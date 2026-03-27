import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class PartnerProjectionRequiredTextValue extends GenericStringValue {
  PartnerProjectionRequiredTextValue({
    super.defaultValue = '',
    super.isRequired = true,
  });
}

class PartnerProjectionOptionalTextValue extends GenericStringValue {
  PartnerProjectionOptionalTextValue({
    super.defaultValue = '',
    super.isRequired = false,
  });
}

PartnerProjectionRequiredTextValue partnerProjectionRequiredText(Object? raw) {
  if (raw is PartnerProjectionRequiredTextValue) {
    return raw;
  }

  final value = PartnerProjectionRequiredTextValue();
  value.parse(raw?.toString() ?? '');
  return value;
}

PartnerProjectionOptionalTextValue partnerProjectionOptionalText(Object? raw) {
  if (raw is PartnerProjectionOptionalTextValue) {
    return raw;
  }

  final value = PartnerProjectionOptionalTextValue();
  value.parse(raw?.toString());
  return value;
}

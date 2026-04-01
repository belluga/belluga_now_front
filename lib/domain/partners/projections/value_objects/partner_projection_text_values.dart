export 'partner_projection_optional_text_value.dart';
export 'partner_projection_required_text_value.dart';

import 'partner_projection_optional_text_value.dart';
import 'partner_projection_required_text_value.dart';

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

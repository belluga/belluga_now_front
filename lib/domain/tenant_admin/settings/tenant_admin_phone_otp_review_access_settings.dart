import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminPhoneOtpReviewAccessSettings {
  TenantAdminPhoneOtpReviewAccessSettings({
    required this.rawPhoneOtpReviewAccessValue,
    this.phoneE164Value,
    this.codeHashValue,
  });

  TenantAdminPhoneOtpReviewAccessSettings.empty()
      : rawPhoneOtpReviewAccessValue = TenantAdminDynamicMapValue(),
        phoneE164Value = null,
        codeHashValue = null;

  final TenantAdminDynamicMapValue rawPhoneOtpReviewAccessValue;
  final TenantAdminOptionalTextValue? phoneE164Value;
  final TenantAdminOptionalTextValue? codeHashValue;

  TenantAdminDynamicMapValue get rawPhoneOtpReviewAccess =>
      rawPhoneOtpReviewAccessValue;
  String? get phoneE164 => phoneE164Value?.nullableValue;
  String? get codeHash => codeHashValue?.nullableValue;
}

import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_resend_email_recipients.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';

class TenantAdminResendEmailSettings {
  TenantAdminResendEmailSettings({
    TenantAdminOptionalTextValue? token,
    TenantAdminOptionalTextValue? from,
    required TenantAdminResendEmailRecipients toRecipients,
    required TenantAdminResendEmailRecipients ccRecipients,
    required TenantAdminResendEmailRecipients bccRecipients,
    required TenantAdminResendEmailRecipients replyToRecipients,
  })  : tokenValue = token,
        fromValue = from,
        toRecipientsValue = toRecipients,
        ccRecipientsValue = ccRecipients,
        bccRecipientsValue = bccRecipients,
        replyToRecipientsValue = replyToRecipients;

  final TenantAdminOptionalTextValue? tokenValue;
  final TenantAdminOptionalTextValue? fromValue;
  final TenantAdminResendEmailRecipients toRecipientsValue;
  final TenantAdminResendEmailRecipients ccRecipientsValue;
  final TenantAdminResendEmailRecipients bccRecipientsValue;
  final TenantAdminResendEmailRecipients replyToRecipientsValue;

  String? get token => tokenValue?.nullableValue;
  String? get from => fromValue?.nullableValue;
  TenantAdminResendEmailRecipients get to => toRecipientsValue;
  TenantAdminResendEmailRecipients get cc => ccRecipientsValue;
  TenantAdminResendEmailRecipients get bcc => bccRecipientsValue;
  TenantAdminResendEmailRecipients get replyTo => replyToRecipientsValue;

  factory TenantAdminResendEmailSettings.empty() {
    return TenantAdminResendEmailSettings(
      toRecipients: TenantAdminResendEmailRecipients(),
      ccRecipients: TenantAdminResendEmailRecipients(),
      bccRecipients: TenantAdminResendEmailRecipients(),
      replyToRecipients: TenantAdminResendEmailRecipients(),
    );
  }
}

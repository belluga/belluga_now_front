import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_positive_int_value.dart';

class TenantAdminOutboundIntegrationsSettings {
  TenantAdminOutboundIntegrationsSettings({
    this.whatsappWebhookUrlValue,
    this.otpWebhookUrlValue,
    required this.otpUseWhatsappWebhookValue,
    required this.otpDeliveryChannelValue,
    required this.otpTtlMinutesValue,
    required this.otpResendCooldownSecondsValue,
    required this.otpMaxAttemptsValue,
  });

  static const deliveryChannelWhatsapp = 'whatsapp';
  static const deliveryChannelSms = 'sms';
  static const defaultOtpTtlMinutes = 10;
  static const defaultOtpResendCooldownSeconds = 60;
  static const defaultOtpMaxAttempts = 5;

  final TenantAdminOptionalUrlValue? whatsappWebhookUrlValue;
  final TenantAdminOptionalUrlValue? otpWebhookUrlValue;
  final TenantAdminBooleanValue otpUseWhatsappWebhookValue;
  final TenantAdminLowercaseTokenValue otpDeliveryChannelValue;
  final TenantAdminPositiveIntValue otpTtlMinutesValue;
  final TenantAdminPositiveIntValue otpResendCooldownSecondsValue;
  final TenantAdminPositiveIntValue otpMaxAttemptsValue;

  String? get whatsappWebhookUrl => whatsappWebhookUrlValue?.nullableValue;
  String? get otpWebhookUrl => otpWebhookUrlValue?.nullableValue;
  bool get otpUseWhatsappWebhook => otpUseWhatsappWebhookValue.value;
  String get otpDeliveryChannel => otpDeliveryChannelValue.value;
  int get otpTtlMinutes => otpTtlMinutesValue.value;
  int get otpResendCooldownSeconds => otpResendCooldownSecondsValue.value;
  int get otpMaxAttempts => otpMaxAttemptsValue.value;

  bool get hasDedicatedOtpWebhook => (otpWebhookUrl ?? '').trim().isNotEmpty;
  bool get hasSmsSecondaryChannel => hasDedicatedOtpWebhook;

  factory TenantAdminOutboundIntegrationsSettings.empty() {
    final otpUseWhatsappWebhookValue = TenantAdminBooleanValue()..parse('true');
    final otpDeliveryChannelValue = TenantAdminLowercaseTokenValue()
      ..parse(deliveryChannelWhatsapp);
    final otpTtlMinutesValue = TenantAdminPositiveIntValue()
      ..parse('$defaultOtpTtlMinutes');
    final otpResendCooldownSecondsValue = TenantAdminPositiveIntValue()
      ..parse('$defaultOtpResendCooldownSeconds');
    final otpMaxAttemptsValue = TenantAdminPositiveIntValue()
      ..parse('$defaultOtpMaxAttempts');
    return TenantAdminOutboundIntegrationsSettings(
      otpUseWhatsappWebhookValue: otpUseWhatsappWebhookValue,
      otpDeliveryChannelValue: otpDeliveryChannelValue,
      otpTtlMinutesValue: otpTtlMinutesValue,
      otpResendCooldownSecondsValue: otpResendCooldownSecondsValue,
      otpMaxAttemptsValue: otpMaxAttemptsValue,
    );
  }
}

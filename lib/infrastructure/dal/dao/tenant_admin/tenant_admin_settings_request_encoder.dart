import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_discovery_filters_settings_value.dart';

class TenantAdminSettingsRequestEncoder {
  const TenantAdminSettingsRequestEncoder();

  Map<String, dynamic> encodeMapUiSettingsPatch(
    TenantAdminMapUiSettings settings,
  ) {
    return encodeSettingsPatchPayload(settings.rawMapUi);
  }

  Map<String, dynamic> encodeDiscoveryFiltersSettingsPatch(
    TenantAdminDiscoveryFiltersSettingsValue settings,
  ) {
    return Map<String, dynamic>.from(settings.rawDiscoveryFilters);
  }

  Map<String, dynamic> encodeAppLinksSettingsPatch(
    TenantAdminAppLinksSettings settings,
  ) {
    return encodeSettingsPatchPayload(settings.rawAppLinks);
  }

  Map<String, dynamic> encodeResendEmailSettingsPatch(
    TenantAdminResendEmailSettings settings,
  ) {
    return encodeSettingsPatchPayload({
      'token': settings.token,
      'from': settings.from,
      'to': settings.to.values.map((entry) => entry.value).toList(),
      'cc': settings.cc.values.map((entry) => entry.value).toList(),
      'bcc': settings.bcc.values.map((entry) => entry.value).toList(),
      'reply_to': settings.replyTo.values.map((entry) => entry.value).toList(),
    });
  }

  Map<String, dynamic> encodeOutboundIntegrationsSettingsPatch(
    TenantAdminOutboundIntegrationsSettings settings,
  ) {
    return encodeSettingsPatchPayload({
      'whatsapp': {
        'webhook_url': settings.whatsappWebhookUrl,
      },
      'otp': {
        'webhook_url': settings.otpWebhookUrl,
        'use_whatsapp_webhook': settings.otpUseWhatsappWebhook,
        'delivery_channel': settings.otpDeliveryChannel,
        'ttl_minutes': settings.otpTtlMinutes,
        'resend_cooldown_seconds': settings.otpResendCooldownSeconds,
        'max_attempts': settings.otpMaxAttempts,
      },
    });
  }

  Map<String, dynamic> encodePhoneOtpReviewAccessSettingsPatch(
    TenantAdminPhoneOtpReviewAccessSettings settings,
  ) {
    return encodeSettingsPatchPayload(
      settings.rawPhoneOtpReviewAccess.value,
    );
  }

  Map<String, dynamic> encodePhoneOtpReviewAccessCodeHashRequest({
    required TenantAdminRequiredTextValue code,
  }) {
    return <String, dynamic>{
      'code': code.value,
    };
  }

  Map<String, dynamic> encodeSettingsPatchPayload(
    Map<String, dynamic> source,
  ) {
    final flattened = <String, dynamic>{};
    _flattenSettingsPayload(
      source,
      flattened,
      prefix: null,
    );
    return flattened;
  }

  void _flattenSettingsPayload(
    Map<String, dynamic> source,
    Map<String, dynamic> output, {
    required String? prefix,
  }) {
    source.forEach((rawKey, value) {
      final key = rawKey.trim();
      if (key.isEmpty) {
        return;
      }

      final path = prefix == null ? key : '$prefix.$key';
      if (value is Map) {
        _flattenSettingsPayload(
          Map<String, dynamic>.from(value),
          output,
          prefix: path,
        );
        return;
      }

      output[path] = value;
    });
  }
}

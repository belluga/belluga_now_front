import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';

class TenantAdminSettingsRequestEncoder {
  const TenantAdminSettingsRequestEncoder();

  Map<String, dynamic> encodeMapUiSettingsPatch(
    TenantAdminMapUiSettings settings,
  ) {
    return encodeSettingsPatchPayload(settings.rawMapUi);
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

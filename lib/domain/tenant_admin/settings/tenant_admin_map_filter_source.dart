import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_token_value.dart';

enum TenantAdminMapFilterSource {
  accountProfile,
  staticAsset,
  event;

  TenantAdminTokenValue get apiValueValue => switch (this) {
        TenantAdminMapFilterSource.accountProfile =>
          TenantAdminTokenValue('account_profile'),
        TenantAdminMapFilterSource.staticAsset =>
          TenantAdminTokenValue('static_asset'),
        TenantAdminMapFilterSource.event => TenantAdminTokenValue('event'),
      };

  TenantAdminTokenValue get labelValue => switch (this) {
        TenantAdminMapFilterSource.accountProfile =>
          TenantAdminTokenValue('Conta'),
        TenantAdminMapFilterSource.staticAsset =>
          TenantAdminTokenValue('Asset'),
        TenantAdminMapFilterSource.event => TenantAdminTokenValue('Evento'),
      };

  String get apiValue => apiValueValue.value;
  String get label => labelValue.value;

  static TenantAdminMapFilterSource? fromRaw(
      TenantAdminLowercaseTokenValue? raw) {
    final normalized = raw?.value;
    for (final candidate in TenantAdminMapFilterSource.values) {
      if (candidate.apiValue == normalized) {
        return candidate;
      }
    }
    return null;
  }
}

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_token_value.dart';

enum TenantAdminMapFilterSource {
  accountProfile(
    TenantAdminTokenValue('account_profile'),
    TenantAdminTokenValue('Conta'),
  ),
  staticAsset(
    TenantAdminTokenValue('static_asset'),
    TenantAdminTokenValue('Asset'),
  ),
  event(
    TenantAdminTokenValue('event'),
    TenantAdminTokenValue('Evento'),
  );

  const TenantAdminMapFilterSource(this.apiValueValue, this.labelValue);

  final TenantAdminTokenValue apiValueValue;
  final TenantAdminTokenValue labelValue;

  String get apiValue => apiValueValue.value;
  String get label => labelValue.value;

  static TenantAdminMapFilterSource? fromRaw(TenantAdminLowercaseTokenValue? raw) {
    final normalized = raw?.value;
    for (final candidate in TenantAdminMapFilterSource.values) {
      if (candidate.apiValue == normalized) {
        return candidate;
      }
    }
    return null;
  }
}

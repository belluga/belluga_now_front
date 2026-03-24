import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_token_value.dart';

typedef TenantAdminMapFilterSourcePrimString = String;
typedef TenantAdminMapFilterSourcePrimInt = int;
typedef TenantAdminMapFilterSourcePrimBool = bool;
typedef TenantAdminMapFilterSourcePrimDouble = double;
typedef TenantAdminMapFilterSourcePrimDateTime = DateTime;
typedef TenantAdminMapFilterSourcePrimDynamic = dynamic;

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

  TenantAdminMapFilterSourcePrimString get apiValue => apiValueValue.value;
  TenantAdminMapFilterSourcePrimString get label => labelValue.value;

  static TenantAdminMapFilterSource? fromRaw(
      TenantAdminMapFilterSourcePrimString? raw) {
    final normalized = raw?.trim().toLowerCase();
    for (final candidate in TenantAdminMapFilterSource.values) {
      if (candidate.apiValue == normalized) {
        return candidate;
      }
    }
    return null;
  }
}

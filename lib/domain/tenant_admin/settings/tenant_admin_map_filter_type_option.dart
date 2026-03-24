import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

typedef TenantAdminMapFilterTypeOptionPrimString = String;
typedef TenantAdminMapFilterTypeOptionPrimInt = int;
typedef TenantAdminMapFilterTypeOptionPrimBool = bool;
typedef TenantAdminMapFilterTypeOptionPrimDouble = double;
typedef TenantAdminMapFilterTypeOptionPrimDateTime = DateTime;
typedef TenantAdminMapFilterTypeOptionPrimDynamic = dynamic;

class TenantAdminMapFilterTypeOption {
  TenantAdminMapFilterTypeOption({
    required TenantAdminMapFilterTypeOptionPrimString slug,
    required TenantAdminMapFilterTypeOptionPrimString label,
  })  : slugValue = _buildSlugValue(slug),
        labelValue = _buildLabelValue(label);

  final TenantAdminLowercaseTokenValue slugValue;
  final TenantAdminRequiredTextValue labelValue;

  TenantAdminMapFilterTypeOptionPrimString get slug => slugValue.value;
  TenantAdminMapFilterTypeOptionPrimString get label => labelValue.value;

  static TenantAdminLowercaseTokenValue _buildSlugValue(
      TenantAdminMapFilterTypeOptionPrimString raw) {
    final value = TenantAdminLowercaseTokenValue()..parse(raw);
    return value;
  }

  static TenantAdminRequiredTextValue _buildLabelValue(
      TenantAdminMapFilterTypeOptionPrimString raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }
}

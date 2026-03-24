import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

typedef TenantAdminMapFilterTaxonomyTermOptionPrimString = String;
typedef TenantAdminMapFilterTaxonomyTermOptionPrimInt = int;
typedef TenantAdminMapFilterTaxonomyTermOptionPrimBool = bool;
typedef TenantAdminMapFilterTaxonomyTermOptionPrimDouble = double;
typedef TenantAdminMapFilterTaxonomyTermOptionPrimDateTime = DateTime;
typedef TenantAdminMapFilterTaxonomyTermOptionPrimDynamic = dynamic;

class TenantAdminMapFilterTaxonomyTermOption {
  TenantAdminMapFilterTaxonomyTermOption({
    required TenantAdminMapFilterTaxonomyTermOptionPrimString token,
    required TenantAdminMapFilterTaxonomyTermOptionPrimString label,
    required TenantAdminMapFilterTaxonomyTermOptionPrimString taxonomySlug,
    required TenantAdminMapFilterTaxonomyTermOptionPrimString taxonomyLabel,
  })  : tokenValue = _buildTokenValue(token),
        labelValue = _buildLabelValue(label),
        taxonomySlugValue = _buildTokenValue(taxonomySlug),
        taxonomyLabelValue = _buildLabelValue(taxonomyLabel);

  final TenantAdminLowercaseTokenValue tokenValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminLowercaseTokenValue taxonomySlugValue;
  final TenantAdminRequiredTextValue taxonomyLabelValue;

  TenantAdminMapFilterTaxonomyTermOptionPrimString get token =>
      tokenValue.value;
  TenantAdminMapFilterTaxonomyTermOptionPrimString get label =>
      labelValue.value;
  TenantAdminMapFilterTaxonomyTermOptionPrimString get taxonomySlug =>
      taxonomySlugValue.value;
  TenantAdminMapFilterTaxonomyTermOptionPrimString get taxonomyLabel =>
      taxonomyLabelValue.value;

  static TenantAdminLowercaseTokenValue _buildTokenValue(
      TenantAdminMapFilterTaxonomyTermOptionPrimString raw) {
    final value = TenantAdminLowercaseTokenValue()..parse(raw);
    return value;
  }

  static TenantAdminRequiredTextValue _buildLabelValue(
      TenantAdminMapFilterTaxonomyTermOptionPrimString raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }
}

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminMapFilterTaxonomyTermOption {
  TenantAdminMapFilterTaxonomyTermOption({
    required this.tokenValue,
    required this.labelValue,
    required this.taxonomySlugValue,
    required this.taxonomyLabelValue,
  });

  final TenantAdminLowercaseTokenValue tokenValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminLowercaseTokenValue taxonomySlugValue;
  final TenantAdminRequiredTextValue taxonomyLabelValue;

  String get token => tokenValue.value;
  String get label => labelValue.value;
  String get taxonomySlug => taxonomySlugValue.value;
  String get taxonomyLabel => taxonomyLabelValue.value;
}

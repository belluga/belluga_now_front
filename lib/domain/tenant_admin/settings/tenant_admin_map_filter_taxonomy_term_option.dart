import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminMapFilterTaxonomyTermOption {
  TenantAdminMapFilterTaxonomyTermOption({
    required String token,
    required String label,
    required String taxonomySlug,
    required String taxonomyLabel,
  })  : tokenValue = _buildTokenValue(token),
        labelValue = _buildLabelValue(label),
        taxonomySlugValue = _buildTokenValue(taxonomySlug),
        taxonomyLabelValue = _buildLabelValue(taxonomyLabel);

  final TenantAdminLowercaseTokenValue tokenValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminLowercaseTokenValue taxonomySlugValue;
  final TenantAdminRequiredTextValue taxonomyLabelValue;

  String get token => tokenValue.value;
  String get label => labelValue.value;
  String get taxonomySlug => taxonomySlugValue.value;
  String get taxonomyLabel => taxonomyLabelValue.value;

  static TenantAdminLowercaseTokenValue _buildTokenValue(String raw) {
    final value = TenantAdminLowercaseTokenValue()..parse(raw);
    return value;
  }

  static TenantAdminRequiredTextValue _buildLabelValue(String raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }
}

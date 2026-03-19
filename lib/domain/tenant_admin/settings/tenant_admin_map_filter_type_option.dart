import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminMapFilterTypeOption {
  TenantAdminMapFilterTypeOption({
    required String slug,
    required String label,
  })  : slugValue = _buildSlugValue(slug),
        labelValue = _buildLabelValue(label);

  final TenantAdminLowercaseTokenValue slugValue;
  final TenantAdminRequiredTextValue labelValue;

  String get slug => slugValue.value;
  String get label => labelValue.value;

  static TenantAdminLowercaseTokenValue _buildSlugValue(String raw) {
    final value = TenantAdminLowercaseTokenValue()..parse(raw);
    return value;
  }

  static TenantAdminRequiredTextValue _buildLabelValue(String raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }
}

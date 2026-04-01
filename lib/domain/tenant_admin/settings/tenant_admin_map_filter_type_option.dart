import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminMapFilterTypeOption {
  TenantAdminMapFilterTypeOption({
    required this.slugValue,
    required this.labelValue,
  });

  final TenantAdminLowercaseTokenValue slugValue;
  final TenantAdminRequiredTextValue labelValue;

  String get slug => slugValue.value;
  String get label => labelValue.value;
}

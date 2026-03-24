import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminTaxonomyTerm {
  TenantAdminTaxonomyTerm({
    required Object type,
    required Object value,
  })  : typeValue = tenantAdminRequiredText(type),
        valueField = tenantAdminRequiredText(value);

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue valueField;

  String get type => typeValue.value;
  String get value => valueField.value;
}

export 'value_objects/tenant_admin_taxonomy_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminTaxonomyTerm {
  TenantAdminTaxonomyTerm({
    required this.typeValue,
    required this.valueField,
  });

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue valueField;

  String get type => typeValue.value;
  String get value => valueField.value;
}

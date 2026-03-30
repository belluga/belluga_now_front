export 'value_objects/tenant_admin_taxonomy_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminTaxonomyTermDefinition {
  TenantAdminTaxonomyTermDefinition({
    required this.idValue,
    required this.taxonomyIdValue,
    required this.slugValue,
    required this.nameValue,
  });

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue taxonomyIdValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminRequiredTextValue nameValue;

  String get id => idValue.value;
  String get taxonomyId => taxonomyIdValue.value;
  String get slug => slugValue.value;
  String get name => nameValue.value;
}

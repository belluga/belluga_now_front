import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminTaxonomyTermDefinition {
  TenantAdminTaxonomyTermDefinition({
    required Object id,
    required Object taxonomyId,
    required Object slug,
    required Object name,
  })  : idValue = tenantAdminRequiredText(id),
        taxonomyIdValue = tenantAdminRequiredText(taxonomyId),
        slugValue = tenantAdminRequiredText(slug),
        nameValue = tenantAdminRequiredText(name);

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue taxonomyIdValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminRequiredTextValue nameValue;

  String get id => idValue.value;
  String get taxonomyId => taxonomyIdValue.value;
  String get slug => slugValue.value;
  String get name => nameValue.value;
}

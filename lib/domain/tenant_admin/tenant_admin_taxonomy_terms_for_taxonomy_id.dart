import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminTaxonomyTermsForTaxonomyId {
  TenantAdminTaxonomyTermsForTaxonomyId({
    required this.taxonomyIdValue,
    required List<TenantAdminTaxonomyTermDefinition> terms,
  }) : termsValue = List<TenantAdminTaxonomyTermDefinition>.unmodifiable(terms);

  final TenantAdminRequiredTextValue taxonomyIdValue;
  final List<TenantAdminTaxonomyTermDefinition> termsValue;

  String get taxonomyId => taxonomyIdValue.value;
  List<TenantAdminTaxonomyTermDefinition> get terms => termsValue;
}

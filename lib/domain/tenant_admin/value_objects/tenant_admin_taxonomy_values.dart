import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminTaxonomy tenantAdminTaxonomyFromRaw({
  required Object? id,
  required Object? slug,
  required Object? name,
  required Object? appliesTo,
  Object? icon,
  Object? color,
}) {
  return TenantAdminTaxonomy(
    idValue: tenantAdminRequiredText(id),
    slugValue: tenantAdminRequiredText(slug),
    nameValue: tenantAdminRequiredText(name),
    appliesToValue: tenantAdminTrimmedStringList(appliesTo),
    iconValue: tenantAdminOptionalText(icon),
    colorValue: tenantAdminOptionalText(color),
  );
}

TenantAdminTaxonomyDefinition tenantAdminTaxonomyDefinitionFromRaw({
  required Object? id,
  required Object? slug,
  required Object? name,
  required Object? appliesTo,
  Object? icon,
  Object? color,
}) {
  return TenantAdminTaxonomyDefinition(
    idValue: tenantAdminRequiredText(id),
    slugValue: tenantAdminRequiredText(slug),
    nameValue: tenantAdminRequiredText(name),
    appliesToValue: tenantAdminTrimmedStringList(appliesTo),
    iconValue: tenantAdminOptionalText(icon),
    colorValue: tenantAdminOptionalText(color),
  );
}

TenantAdminTaxonomyTerm tenantAdminTaxonomyTermFromRaw({
  required Object? type,
  required Object? value,
  Object? name,
  Object? taxonomyName,
  Object? label,
}) {
  return TenantAdminTaxonomyTerm(
    typeValue: tenantAdminRequiredText(type),
    valueField: tenantAdminRequiredText(value),
    nameValue: tenantAdminOptionalText(name),
    taxonomyNameValue: tenantAdminOptionalText(taxonomyName),
    labelValue: tenantAdminOptionalText(label),
  );
}

TenantAdminTaxonomyTermDefinition tenantAdminTaxonomyTermDefinitionFromRaw({
  required Object? id,
  required Object? taxonomyId,
  required Object? slug,
  required Object? name,
}) {
  return TenantAdminTaxonomyTermDefinition(
    idValue: tenantAdminRequiredText(id),
    taxonomyIdValue: tenantAdminRequiredText(taxonomyId),
    slugValue: tenantAdminRequiredText(slug),
    nameValue: tenantAdminRequiredText(name),
  );
}

import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

TenantAdminStaticAsset tenantAdminStaticAssetFromRaw({
  required Object? id,
  required Object? profileType,
  required Object? displayName,
  required Object? slug,
  required Object? isActive,
  Object? avatarUrl,
  Object? coverUrl,
  Object? bio,
  Object? content,
  TenantAdminTaxonomyTerms taxonomyTerms =
      const TenantAdminTaxonomyTerms.empty(),
  TenantAdminLocation? location,
}) {
  return TenantAdminStaticAsset(
    idValue: tenantAdminRequiredText(id),
    profileTypeValue: tenantAdminRequiredText(profileType),
    displayNameValue: tenantAdminRequiredText(displayName),
    slugValue: tenantAdminRequiredText(slug),
    isActiveValue: tenantAdminFlag(isActive),
    avatarUrlValue: tenantAdminOptionalUrl(avatarUrl),
    coverUrlValue: tenantAdminOptionalUrl(coverUrl),
    bioValue: tenantAdminOptionalText(bio),
    contentValue: tenantAdminOptionalText(content),
    taxonomyTerms: taxonomyTerms,
    location: location,
  );
}

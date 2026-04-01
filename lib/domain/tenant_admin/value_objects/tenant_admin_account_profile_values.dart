import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

TenantAdminAccountProfile tenantAdminAccountProfileFromRaw({
  required Object? id,
  required Object? accountId,
  required Object? profileType,
  required Object? displayName,
  Object? slug,
  Object? avatarUrl,
  Object? coverUrl,
  Object? bio,
  Object? content,
  TenantAdminLocation? location,
  TenantAdminTaxonomyTerms taxonomyTerms =
      const TenantAdminTaxonomyTerms.empty(),
  TenantAdminOwnershipState? ownershipState,
}) {
  return TenantAdminAccountProfile(
    idValue: tenantAdminRequiredText(id),
    accountIdValue: tenantAdminRequiredText(accountId),
    profileTypeValue: tenantAdminRequiredText(profileType),
    displayNameValue: tenantAdminRequiredText(displayName),
    slugValue: tenantAdminOptionalText(slug),
    avatarUrlValue: tenantAdminOptionalUrl(avatarUrl),
    coverUrlValue: tenantAdminOptionalUrl(coverUrl),
    bioValue: tenantAdminOptionalText(bio),
    contentValue: tenantAdminOptionalText(content),
    location: location,
    taxonomyTerms: taxonomyTerms,
    ownershipState: ownershipState,
  );
}

import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminAccountProfile {
  TenantAdminAccountProfile({
    required Object id,
    required Object accountId,
    required Object profileType,
    required Object displayName,
    Object? slug,
    Object? avatarUrl,
    Object? coverUrl,
    Object? bio,
    Object? content,
    this.location,
    this.taxonomyTerms = const [],
    this.ownershipState,
  })  : idValue = tenantAdminRequiredText(id),
        accountIdValue = tenantAdminRequiredText(accountId),
        profileTypeValue = tenantAdminRequiredText(profileType),
        displayNameValue = tenantAdminRequiredText(displayName),
        slugValue = tenantAdminOptionalText(slug),
        avatarUrlValue = tenantAdminOptionalUrl(avatarUrl),
        coverUrlValue = tenantAdminOptionalUrl(coverUrl),
        bioValue = tenantAdminOptionalText(bio),
        contentValue = tenantAdminOptionalText(content);

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue accountIdValue;
  final TenantAdminRequiredTextValue profileTypeValue;
  final TenantAdminRequiredTextValue displayNameValue;
  final TenantAdminOptionalTextValue slugValue;
  final TenantAdminOptionalUrlValue avatarUrlValue;
  final TenantAdminOptionalUrlValue coverUrlValue;
  final TenantAdminOptionalTextValue bioValue;
  final TenantAdminOptionalTextValue contentValue;
  final TenantAdminLocation? location;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
  final TenantAdminOwnershipState? ownershipState;

  String get id => idValue.value;
  String get accountId => accountIdValue.value;
  String get profileType => profileTypeValue.value;
  String get displayName => displayNameValue.value;
  String? get slug => slugValue.nullableValue;
  String? get avatarUrl => avatarUrlValue.nullableValue;
  String? get coverUrl => coverUrlValue.nullableValue;
  String? get bio => bioValue.nullableValue;
  String? get content => contentValue.nullableValue;
}

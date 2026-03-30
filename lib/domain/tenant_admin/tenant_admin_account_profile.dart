import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_values.dart';

class TenantAdminAccountProfile {
  TenantAdminAccountProfile({
    required this.idValue,
    required this.accountIdValue,
    required this.profileTypeValue,
    required this.displayNameValue,
    TenantAdminOptionalTextValue? slugValue,
    TenantAdminOptionalUrlValue? avatarUrlValue,
    TenantAdminOptionalUrlValue? coverUrlValue,
    TenantAdminOptionalTextValue? bioValue,
    TenantAdminOptionalTextValue? contentValue,
    this.location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    this.ownershipState,
  })  : slugValue = slugValue ?? TenantAdminOptionalTextValue(),
        avatarUrlValue = avatarUrlValue ?? TenantAdminOptionalUrlValue(),
        coverUrlValue = coverUrlValue ?? TenantAdminOptionalUrlValue(),
        bioValue = bioValue ?? TenantAdminOptionalTextValue(),
        contentValue = contentValue ?? TenantAdminOptionalTextValue(),
        taxonomyTerms = taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty();

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
  final TenantAdminTaxonomyTerms taxonomyTerms;
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

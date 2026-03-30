import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_static_asset_values.dart';

class TenantAdminStaticAsset {
  TenantAdminStaticAsset({
    required this.idValue,
    required this.profileTypeValue,
    required this.displayNameValue,
    required this.slugValue,
    required this.isActiveValue,
    TenantAdminOptionalUrlValue? avatarUrlValue,
    TenantAdminOptionalUrlValue? coverUrlValue,
    TenantAdminOptionalTextValue? bioValue,
    TenantAdminOptionalTextValue? contentValue,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    this.location,
  })  : avatarUrlValue = avatarUrlValue ?? TenantAdminOptionalUrlValue(),
        coverUrlValue = coverUrlValue ?? TenantAdminOptionalUrlValue(),
        bioValue = bioValue ?? TenantAdminOptionalTextValue(),
        contentValue = contentValue ?? TenantAdminOptionalTextValue(),
        taxonomyTerms = taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty();

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue profileTypeValue;
  final TenantAdminRequiredTextValue displayNameValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminFlagValue isActiveValue;
  final TenantAdminOptionalUrlValue avatarUrlValue;
  final TenantAdminOptionalUrlValue coverUrlValue;
  final TenantAdminOptionalTextValue bioValue;
  final TenantAdminOptionalTextValue contentValue;
  final TenantAdminTaxonomyTerms taxonomyTerms;
  final TenantAdminLocation? location;

  String get id => idValue.value;
  String get profileType => profileTypeValue.value;
  String get displayName => displayNameValue.value;
  String get slug => slugValue.value;
  bool get isActive => isActiveValue.value;
  String? get avatarUrl => avatarUrlValue.nullableValue;
  String? get coverUrl => coverUrlValue.nullableValue;
  String? get bio => bioValue.nullableValue;
  String? get content => contentValue.nullableValue;
}

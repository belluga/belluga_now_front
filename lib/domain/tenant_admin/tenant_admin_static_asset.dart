import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminStaticAsset {
  TenantAdminStaticAsset({
    required Object id,
    required Object profileType,
    required Object displayName,
    required Object slug,
    required Object isActive,
    Object? avatarUrl,
    Object? coverUrl,
    Object? bio,
    Object? content,
    this.taxonomyTerms = const [],
    this.location,
  })  : idValue = tenantAdminRequiredText(id),
        profileTypeValue = tenantAdminRequiredText(profileType),
        displayNameValue = tenantAdminRequiredText(displayName),
        slugValue = tenantAdminRequiredText(slug),
        isActiveValue = tenantAdminFlag(isActive),
        avatarUrlValue = tenantAdminOptionalUrl(avatarUrl),
        coverUrlValue = tenantAdminOptionalUrl(coverUrl),
        bioValue = tenantAdminOptionalText(bio),
        contentValue = tenantAdminOptionalText(content);

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue profileTypeValue;
  final TenantAdminRequiredTextValue displayNameValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminFlagValue isActiveValue;
  final TenantAdminOptionalUrlValue avatarUrlValue;
  final TenantAdminOptionalUrlValue coverUrlValue;
  final TenantAdminOptionalTextValue bioValue;
  final TenantAdminOptionalTextValue contentValue;
  final List<TenantAdminTaxonomyTerm> taxonomyTerms;
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

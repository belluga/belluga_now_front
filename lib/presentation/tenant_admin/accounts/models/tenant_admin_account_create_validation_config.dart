import 'package:belluga_form_validation/belluga_form_validation.dart';

abstract final class TenantAdminAccountCreateValidationTargets {
  static const String global = 'global';
  static const String profileType = 'profile_type';
  static const String name = 'name';
  static const String ownership = 'ownership';
  static const String location = 'location';
  static const String taxonomies = 'taxonomies';
  static const String bio = 'bio';
  static const String content = 'content';
  static const String media = 'media';
}

final tenantAdminAccountCreateValidationConfig = FormValidationConfig(
  formId: 'tenant_admin_account_create',
  bindings: <FormValidationBinding>[
    globalAny(
      const <String>['account', 'account_profile'],
      targetId: TenantAdminAccountCreateValidationTargets.global,
    ),
    field(
      'profile_type',
      targetId: TenantAdminAccountCreateValidationTargets.profileType,
    ),
    field(
      'name',
      targetId: TenantAdminAccountCreateValidationTargets.name,
    ),
    group(
      'ownership_state',
      targetId: TenantAdminAccountCreateValidationTargets.ownership,
    ),
    groupAny(
      const <String>[
        'location',
        'location.lat',
        'location.lng',
      ],
      targetId: TenantAdminAccountCreateValidationTargets.location,
    ),
    groupPattern(
      'taxonomy_terms.*.*',
      targetId: TenantAdminAccountCreateValidationTargets.taxonomies,
    ),
    field(
      'bio',
      targetId: TenantAdminAccountCreateValidationTargets.bio,
    ),
    field(
      'content',
      targetId: TenantAdminAccountCreateValidationTargets.content,
    ),
    groupAny(
      const <String>['avatar', 'cover'],
      targetId: TenantAdminAccountCreateValidationTargets.media,
    ),
  ],
);

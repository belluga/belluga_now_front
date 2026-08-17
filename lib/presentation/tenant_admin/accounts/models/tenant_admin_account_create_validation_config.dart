import 'package:belluga_form_validation/belluga_form_validation.dart';

abstract final class TenantAdminAccountCreateValidationTargets {
  static const String global = 'global';
  static const String profileType = 'profile_type';
  static const String name = 'name';
  static const String location = 'location';
}

final tenantAdminAccountCreateValidationConfig = FormValidationConfig(
  formId: 'tenant_admin_account_create',
  bindings: <FormValidationBinding>[
    globalAny(const <String>[
      'account',
      'account_profile',
    ], targetId: TenantAdminAccountCreateValidationTargets.global),
    field(
      'profile_type',
      targetId: TenantAdminAccountCreateValidationTargets.profileType,
    ),
    field('name', targetId: TenantAdminAccountCreateValidationTargets.name),
    groupAny(const <String>[
      'location',
      'location.lat',
      'location.lng',
    ], targetId: TenantAdminAccountCreateValidationTargets.location),
  ],
);

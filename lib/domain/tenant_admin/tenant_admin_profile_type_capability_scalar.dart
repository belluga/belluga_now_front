import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

final class TenantAdminProfileTypeCapabilityScalar {
  const TenantAdminProfileTypeCapabilityScalar.boolean(
    TenantAdminFlagValue value,
  ) : booleanValueObject = value,
      enumValueObject = null;

  const TenantAdminProfileTypeCapabilityScalar.enumeration(
    TenantAdminRequiredTextValue value,
  ) : booleanValueObject = null,
      enumValueObject = value;

  final TenantAdminFlagValue? booleanValueObject;
  final TenantAdminRequiredTextValue? enumValueObject;

  bool get isBoolean => booleanValueObject != null;
  bool get isEnum => enumValueObject != null;
  bool get booleanValue => booleanValueObject?.value ?? false;
  String? get enumValue => enumValueObject?.value;
}

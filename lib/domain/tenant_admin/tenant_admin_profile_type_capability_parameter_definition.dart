import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_validation.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

final class TenantAdminProfileTypeCapabilityParameterDefinition {
  const TenantAdminProfileTypeCapabilityParameterDefinition({
    required this.keyValue,
    required this.defaultValueObject,
    required this.failClosedValueObject,
    required this.validations,
  });

  final TenantAdminRequiredTextValue keyValue;
  final TenantAdminCountValue defaultValueObject;
  final TenantAdminCountValue failClosedValueObject;
  final List<TenantAdminProfileTypeCapabilityValidation> validations;

  String get key => keyValue.value;
  String get valueType => 'integer';
  int get defaultValue => defaultValueObject.value;
  int get failClosedValue => failClosedValueObject.value;

  bool accepts(TenantAdminCountValue candidate) {
    for (final validation in validations) {
      if (validation.rule == 'min' && candidate.value < validation.value) {
        return false;
      }
      if (validation.rule == 'max' && candidate.value > validation.value) {
        return false;
      }
    }
    return true;
  }
}

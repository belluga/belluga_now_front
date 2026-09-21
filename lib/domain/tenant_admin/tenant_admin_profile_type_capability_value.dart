import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_parameter_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_scalar.dart';

final class TenantAdminProfileTypeCapabilityValue {
  const TenantAdminProfileTypeCapabilityValue({
    required this.scalarValue,
    required this.parameters,
  });

  final TenantAdminProfileTypeCapabilityScalar scalarValue;
  final List<TenantAdminProfileTypeCapabilityParameterValue> parameters;

  bool get booleanValue => scalarValue.booleanValue;
  String? get enumValue => scalarValue.enumValue;

  TenantAdminProfileTypeCapabilityValue withScalar(
    TenantAdminProfileTypeCapabilityScalar nextValue,
  ) {
    return TenantAdminProfileTypeCapabilityValue(
      scalarValue: nextValue,
      parameters: parameters,
    );
  }
}

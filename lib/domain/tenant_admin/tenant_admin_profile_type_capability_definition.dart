import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_parameter_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_resource.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_scalar.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

final class TenantAdminProfileTypeCapabilityDefinition {
  const TenantAdminProfileTypeCapabilityDefinition({
    required this.keyValue,
    required this.domainValue,
    required this.defaultValue,
    required this.failClosedValue,
    required this.allowedValueObjects,
    required this.parameters,
    required this.resources,
  });

  final TenantAdminRequiredTextValue keyValue;
  final TenantAdminRequiredTextValue domainValue;
  final TenantAdminProfileTypeCapabilityScalar defaultValue;
  final TenantAdminProfileTypeCapabilityScalar failClosedValue;
  final List<TenantAdminRequiredTextValue> allowedValueObjects;
  final List<TenantAdminProfileTypeCapabilityParameterDefinition> parameters;
  final List<TenantAdminProfileTypeCapabilityResource> resources;

  String get key => keyValue.value;
  String get domain => domainValue.value;
  String get valueType => isBoolean ? 'boolean' : 'enum';
  bool get isBoolean => defaultValue.isBoolean && failClosedValue.isBoolean;
  bool get isEnum => defaultValue.isEnum && failClosedValue.isEnum;
}

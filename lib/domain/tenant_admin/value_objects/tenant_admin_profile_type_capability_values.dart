import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_definition.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_entry.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_operation.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_parameter_definition.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_parameter_value.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_resource.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_scalar.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_validation.dart';
export 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_value.dart';

TenantAdminRequiredTextValue _requiredText(Object? raw) {
  return TenantAdminRequiredTextValue()..parse(raw?.toString() ?? '');
}

TenantAdminProfileTypeCapabilityScalar
tenantAdminProfileTypeCapabilityScalarFromRaw(Object? raw) {
  if (raw is bool) {
    return TenantAdminProfileTypeCapabilityScalar.boolean(
      TenantAdminFlagValue(raw),
    );
  }
  return TenantAdminProfileTypeCapabilityScalar.enumeration(_requiredText(raw));
}

TenantAdminProfileTypeCapabilityValidation
tenantAdminProfileTypeCapabilityValidationFromRaw({
  required Object? rule,
  required Object? value,
}) {
  return TenantAdminProfileTypeCapabilityValidation(
    ruleValue: _requiredText(rule),
    limitValue: TenantAdminCountValue(value is num ? value.toInt() : 0),
  );
}

TenantAdminProfileTypeCapabilityParameterDefinition
tenantAdminProfileTypeCapabilityParameterDefinitionFromRaw({
  required Object? key,
  required Object? valueType,
  required Object? defaultValue,
  required Object? failClosedValue,
  required List<TenantAdminProfileTypeCapabilityValidation> validations,
}) {
  if (valueType?.toString().trim() != 'integer') {
    throw ArgumentError.value(valueType, 'valueType');
  }
  return TenantAdminProfileTypeCapabilityParameterDefinition(
    keyValue: _requiredText(key),
    defaultValueObject: TenantAdminCountValue(
      defaultValue is num ? defaultValue.toInt() : 0,
    ),
    failClosedValueObject: TenantAdminCountValue(
      failClosedValue is num ? failClosedValue.toInt() : 0,
    ),
    validations: List.unmodifiable(validations),
  );
}

TenantAdminProfileTypeCapabilityParameterValue
tenantAdminProfileTypeCapabilityParameterValueFromRaw({
  required Object? key,
  required Object? value,
}) {
  return TenantAdminProfileTypeCapabilityParameterValue(
    keyValue: _requiredText(key),
    valueObject: TenantAdminCountValue(value is num ? value.toInt() : 0),
  );
}

TenantAdminProfileTypeCapabilityOperation
tenantAdminProfileTypeCapabilityOperationFromRaw({
  required Object? key,
  required Object? ability,
}) {
  return TenantAdminProfileTypeCapabilityOperation(
    keyValue: _requiredText(key),
    abilityValue: _requiredText(ability),
  );
}

TenantAdminProfileTypeCapabilityResource
tenantAdminProfileTypeCapabilityResourceFromRaw({
  required Object? key,
  required List<TenantAdminProfileTypeCapabilityOperation> operations,
}) {
  return TenantAdminProfileTypeCapabilityResource(
    keyValue: _requiredText(key),
    operations: List.unmodifiable(operations),
  );
}

TenantAdminProfileTypeCapabilityDefinition
tenantAdminProfileTypeCapabilityDefinitionFromRaw({
  required Object? key,
  required Object? domain,
  required Object? valueType,
  required Object? defaultValue,
  required Object? failClosedValue,
  required List<String> allowedValues,
  required List<TenantAdminProfileTypeCapabilityParameterDefinition> parameters,
  required List<TenantAdminProfileTypeCapabilityResource> resources,
}) {
  final normalizedType = valueType?.toString().trim();
  if (normalizedType != 'boolean' && normalizedType != 'enum') {
    throw ArgumentError.value(valueType, 'valueType');
  }
  return TenantAdminProfileTypeCapabilityDefinition(
    keyValue: _requiredText(key),
    domainValue: _requiredText(domain),
    defaultValue: tenantAdminProfileTypeCapabilityScalarFromRaw(defaultValue),
    failClosedValue: tenantAdminProfileTypeCapabilityScalarFromRaw(
      failClosedValue,
    ),
    allowedValueObjects: List.unmodifiable(allowedValues.map(_requiredText)),
    parameters: List.unmodifiable(parameters),
    resources: List.unmodifiable(resources),
  );
}

TenantAdminProfileTypeCapabilityValue
tenantAdminProfileTypeCapabilityValueFromRaw({
  required Object? value,
  Map<String, int> parameters = const <String, int>{},
}) {
  return TenantAdminProfileTypeCapabilityValue(
    scalarValue: tenantAdminProfileTypeCapabilityScalarFromRaw(value),
    parameters: List.unmodifiable(
      parameters.entries.map(
        (entry) => tenantAdminProfileTypeCapabilityParameterValueFromRaw(
          key: entry.key,
          value: entry.value,
        ),
      ),
    ),
  );
}

TenantAdminProfileTypeCapabilities tenantAdminProfileTypeCapabilitiesFromRaw(
  Map<String, TenantAdminProfileTypeCapabilityValue> values,
) {
  return TenantAdminProfileTypeCapabilities(
    values.entries.map(
      (entry) => TenantAdminProfileTypeCapabilityEntry(
        keyValue: _requiredText(entry.key),
        configured: entry.value,
        effective: entry.value,
      ),
    ),
  );
}

import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/support/tenant_admin_poi_visual_json_normalizer.dart';

class TenantAdminProfileTypeDTO {
  const TenantAdminProfileTypeDTO({
    required this.type,
    required this.label,
    required this.pluralLabel,
    required this.allowedTaxonomies,
    required this.capabilities,
    required this.capabilityCreationConfiguration,
    required this.capabilityDefinitions,
    required this.capabilityRevision,
    this.visual,
  });

  final String type;
  final String label;
  final String pluralLabel;
  final List<String> allowedTaxonomies;
  final TenantAdminPoiVisual? visual;
  final TenantAdminProfileTypeCapabilities capabilities;
  final TenantAdminProfileTypeCapabilities capabilityCreationConfiguration;
  final List<TenantAdminProfileTypeCapabilityDefinition> capabilityDefinitions;
  final int capabilityRevision;

  factory TenantAdminProfileTypeDTO.fromJson(
    Map<String, dynamic> json, {
    List<TenantAdminProfileTypeCapabilityDefinition> capabilityDefinitions =
        const <TenantAdminProfileTypeCapabilityDefinition>[],
    TenantAdminProfileTypeCapabilities capabilityCreationConfiguration =
        const TenantAdminProfileTypeCapabilities.empty(),
  }) {
    final allowed = <String>[];
    final raw = json['allowed_taxonomies'];
    if (raw is List) {
      for (final entry in raw) {
        if (entry != null) {
          allowed.add(entry.toString());
        }
      }
    }
    final labelsRaw = json['labels'];
    final labels = labelsRaw is Map
        ? Map<String, dynamic>.from(labelsRaw)
        : const <String, dynamic>{};
    final singularLabel = labels['singular']?.toString().trim();
    final pluralLabel = labels['plural']?.toString().trim();
    final visualRaw = tenantAdminResolvePoiVisualRaw(
      visualRaw: json['visual'] ?? json['poi_visual'],
      typeAssetUrl: json['type_asset_url'],
    );
    final revision = json['capability_revision'];
    return TenantAdminProfileTypeDTO(
      type: json['type']?.toString() ?? '',
      label: singularLabel != null && singularLabel.isNotEmpty
          ? singularLabel
          : json['label']?.toString() ?? '',
      pluralLabel: pluralLabel != null && pluralLabel.isNotEmpty
          ? pluralLabel
          : singularLabel != null && singularLabel.isNotEmpty
          ? singularLabel
          : json['label']?.toString() ?? '',
      allowedTaxonomies: allowed,
      visual: tenantAdminPoiVisualFromRaw(visualRaw),
      capabilities: tenantAdminResolvedCapabilitiesFromRaw(
        json['capabilities'],
        capabilityDefinitions,
      ),
      capabilityCreationConfiguration: capabilityCreationConfiguration,
      capabilityDefinitions: List.unmodifiable(capabilityDefinitions),
      capabilityRevision: revision is num ? revision.toInt() : 0,
    );
  }

  TenantAdminProfileTypeDefinition toDomain() {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type,
      label: label,
      pluralLabel: pluralLabel,
      allowedTaxonomies: allowedTaxonomies,
      visual: visual,
      capabilities: capabilities,
      capabilityCreationConfiguration: capabilityCreationConfiguration,
      capabilityDefinitions: capabilityDefinitions,
      capabilityRevision: capabilityRevision,
    );
  }
}

List<TenantAdminProfileTypeCapabilityDefinition>
tenantAdminCapabilityDefinitionsFromRaw(Object? raw) {
  if (raw is! List) {
    return const <TenantAdminProfileTypeCapabilityDefinition>[];
  }

  final definitions = <TenantAdminProfileTypeCapabilityDefinition>[];
  for (final rawDefinition in raw) {
    if (rawDefinition is! Map) {
      continue;
    }
    final definition = Map<String, dynamic>.from(rawDefinition);
    final key = definition['key']?.toString().trim() ?? '';
    final domain = definition['domain']?.toString().trim() ?? '';
    final valueType = definition['value_type']?.toString().trim() ?? '';
    final defaultValue = definition['default_value'];
    final failClosedValue = definition['fail_closed_value'];
    if (key.isEmpty ||
        domain.isEmpty ||
        !_validDeclaredValue(valueType, defaultValue, definition) ||
        !_validDeclaredValue(valueType, failClosedValue, definition)) {
      continue;
    }

    final parameters = _decodeParameterDefinitions(definition['parameters']);
    final resources = _decodeResources(definition['resources']);
    final allowedValues = definition['allowed_values'] is List
        ? (definition['allowed_values'] as List).whereType<String>().toList(
            growable: false,
          )
        : const <String>[];
    definitions.add(
      tenantAdminProfileTypeCapabilityDefinitionFromRaw(
        key: key,
        domain: domain,
        valueType: valueType,
        defaultValue: defaultValue,
        failClosedValue: failClosedValue,
        allowedValues: List.unmodifiable(allowedValues),
        parameters: List.unmodifiable(parameters),
        resources: List.unmodifiable(resources),
      ),
    );
  }
  return List.unmodifiable(definitions);
}

TenantAdminProfileTypeCapabilities tenantAdminResolvedCapabilitiesFromRaw(
  Object? raw,
  List<TenantAdminProfileTypeCapabilityDefinition> definitions,
) {
  final rawCapabilities = raw is Map
      ? Map<String, dynamic>.from(raw)
      : const <String, dynamic>{};
  final entries = <TenantAdminProfileTypeCapabilityEntry>[];

  for (final definition in definitions) {
    final rawEnvelope = rawCapabilities[definition.key];
    final envelope = rawEnvelope is Map
        ? Map<String, dynamic>.from(rawEnvelope)
        : const <String, dynamic>{};
    final configured = _decodeCapabilityValue(
      envelope['configured'],
      definition,
    );
    final effective = _decodeCapabilityValue(envelope['effective'], definition);
    entries.add(
      TenantAdminProfileTypeCapabilityEntry(
        keyValue: definition.keyValue,
        configured: configured,
        effective: effective,
      ),
    );
  }

  return TenantAdminProfileTypeCapabilities(entries);
}

TenantAdminProfileTypeCapabilities tenantAdminConfiguredCapabilitiesFromRaw(
  Object? raw,
  List<TenantAdminProfileTypeCapabilityDefinition> definitions,
) {
  final rawCapabilities = raw is Map
      ? Map<String, dynamic>.from(raw)
      : const <String, dynamic>{};
  return TenantAdminProfileTypeCapabilities(
    definitions.map((definition) {
      return TenantAdminProfileTypeCapabilityEntry(
        keyValue: definition.keyValue,
        configured: _decodeCapabilityValue(
          rawCapabilities[definition.key],
          definition,
        ),
      );
    }),
  );
}

TenantAdminProfileTypeCapabilityValue _decodeCapabilityValue(
  Object? raw,
  TenantAdminProfileTypeCapabilityDefinition definition,
) {
  final envelope = raw is Map
      ? Map<String, dynamic>.from(raw)
      : const <String, dynamic>{};
  final candidate = envelope['value'];
  final value = _validEffectiveValue(definition, candidate)
      ? tenantAdminProfileTypeCapabilityScalarFromRaw(candidate)
      : definition.failClosedValue;
  final rawParameters = envelope['parameters'] is Map
      ? Map<String, dynamic>.from(envelope['parameters'] as Map)
      : const <String, dynamic>{};
  final parameters = <TenantAdminProfileTypeCapabilityParameterValue>[];
  for (final parameter in definition.parameters) {
    final candidate = rawParameters[parameter.key];
    parameters.add(
      tenantAdminProfileTypeCapabilityParameterValueFromRaw(
        key: parameter.key,
        value: _validParameterValue(parameter, candidate)
            ? candidate
            : parameter.failClosedValue,
      ),
    );
  }
  return TenantAdminProfileTypeCapabilityValue(
    scalarValue: value,
    parameters: List.unmodifiable(parameters),
  );
}

List<TenantAdminProfileTypeCapabilityParameterDefinition>
_decodeParameterDefinitions(Object? raw) {
  if (raw is! List) {
    return const <TenantAdminProfileTypeCapabilityParameterDefinition>[];
  }
  final result = <TenantAdminProfileTypeCapabilityParameterDefinition>[];
  for (final entry in raw) {
    if (entry is! Map) {
      continue;
    }
    final parameter = Map<String, dynamic>.from(entry);
    final key = parameter['key']?.toString().trim() ?? '';
    final valueType = parameter['value_type']?.toString().trim() ?? '';
    final defaultValue = parameter['default_value'];
    final failClosedValue = parameter['fail_closed_value'];
    if (key.isEmpty ||
        valueType != 'integer' ||
        defaultValue is! int ||
        failClosedValue is! int) {
      continue;
    }
    final validations = <TenantAdminProfileTypeCapabilityValidation>[];
    final rawValidations = parameter['validations'];
    if (rawValidations is List) {
      for (final rawValidation in rawValidations) {
        if (rawValidation is! Map) {
          continue;
        }
        final validation = Map<String, dynamic>.from(rawValidation);
        final rule = validation['rule']?.toString().trim() ?? '';
        final value = validation['value'];
        if ((rule == 'min' || rule == 'max') && value is int) {
          validations.add(
            tenantAdminProfileTypeCapabilityValidationFromRaw(
              rule: rule,
              value: value,
            ),
          );
        }
      }
    }
    result.add(
      tenantAdminProfileTypeCapabilityParameterDefinitionFromRaw(
        key: key,
        valueType: valueType,
        defaultValue: defaultValue,
        failClosedValue: failClosedValue,
        validations: List.unmodifiable(validations),
      ),
    );
  }
  return result;
}

List<TenantAdminProfileTypeCapabilityResource> _decodeResources(Object? raw) {
  if (raw is! Map) {
    return const <TenantAdminProfileTypeCapabilityResource>[];
  }
  final result = <TenantAdminProfileTypeCapabilityResource>[];
  for (final entry in raw.entries) {
    if (entry.value is! Map) {
      continue;
    }
    final resource = Map<String, dynamic>.from(entry.value as Map);
    final operations = <TenantAdminProfileTypeCapabilityOperation>[];
    final rawOperations = resource['operations'];
    if (rawOperations is List) {
      for (final rawOperation in rawOperations) {
        if (rawOperation is! Map) {
          continue;
        }
        final operation = Map<String, dynamic>.from(rawOperation);
        final key = operation['key']?.toString().trim() ?? '';
        final ability = operation['ability']?.toString().trim() ?? '';
        if (key.isNotEmpty && ability.isNotEmpty) {
          operations.add(
            tenantAdminProfileTypeCapabilityOperationFromRaw(
              key: key,
              ability: ability,
            ),
          );
        }
      }
    }
    result.add(
      tenantAdminProfileTypeCapabilityResourceFromRaw(
        key: entry.key.toString(),
        operations: List.unmodifiable(operations),
      ),
    );
  }
  return result;
}

bool _validDeclaredValue(
  String valueType,
  Object? value,
  Map<String, dynamic> definition,
) {
  if (valueType == 'boolean') {
    return value is bool;
  }
  if (valueType != 'enum' || value is! String) {
    return false;
  }
  final allowed = definition['allowed_values'];
  return allowed is List && allowed.whereType<String>().contains(value);
}

bool _validEffectiveValue(
  TenantAdminProfileTypeCapabilityDefinition definition,
  Object? value,
) {
  if (definition.isBoolean) {
    return value is bool;
  }
  return definition.isEnum &&
      value is String &&
      definition.allowedValueObjects.any(
        (allowedValue) => allowedValue.value == value,
      );
}

bool _validParameterValue(
  TenantAdminProfileTypeCapabilityParameterDefinition parameter,
  Object? value,
) {
  if (value is! int) {
    return false;
  }
  for (final validation in parameter.validations) {
    if (validation.rule == 'min' && value < validation.value) {
      return false;
    }
    if (validation.rule == 'max' && value > validation.value) {
      return false;
    }
  }
  return true;
}

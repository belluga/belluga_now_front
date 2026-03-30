export 'telemetry_repository_contract_bool_value.dart';
export 'telemetry_repository_contract_double_value.dart';
export 'telemetry_repository_contract_int_value.dart';
export 'telemetry_repository_contract_text_value.dart';

import 'package:belluga_now/domain/repositories/telemetry_repository_contract_properties.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract_property.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract_property_value.dart';
import 'telemetry_repository_contract_bool_value.dart';
import 'telemetry_repository_contract_double_value.dart';
import 'telemetry_repository_contract_int_value.dart';
import 'telemetry_repository_contract_text_value.dart';

TelemetryRepositoryContractTextValue telemetryRepoString(
  Object? raw, {
  String defaultValue = '',
  bool isRequired = true,
}) {
  if (raw is TelemetryRepositoryContractTextValue) {
    return raw;
  }
  return TelemetryRepositoryContractTextValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TelemetryRepositoryContractBoolValue telemetryRepoBool(
  Object? raw, {
  bool defaultValue = false,
  bool isRequired = true,
}) {
  if (raw is TelemetryRepositoryContractBoolValue) {
    return raw;
  }
  return TelemetryRepositoryContractBoolValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TelemetryRepositoryContractIntValue telemetryRepoInt(
  Object? raw, {
  int defaultValue = 0,
  bool isRequired = false,
}) {
  if (raw is TelemetryRepositoryContractIntValue) {
    return raw;
  }
  return TelemetryRepositoryContractIntValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TelemetryRepositoryContractDoubleValue telemetryRepoDouble(
  Object? raw, {
  double defaultValue = 0,
  bool isRequired = false,
}) {
  if (raw is TelemetryRepositoryContractDoubleValue) {
    return raw;
  }
  return TelemetryRepositoryContractDoubleValue.fromRaw(
    raw,
    defaultValue: defaultValue,
    isRequired: isRequired,
  );
}

TelemetryRepositoryContractProperties telemetryRepoMap(
  Object? raw, {
  Map<String, Object?> defaultValue = const <String, Object?>{},
}) {
  if (raw is TelemetryRepositoryContractProperties) {
    return raw;
  }
  if (raw is Map) {
    return _telemetryPropertiesFromMap(Map<Object?, Object?>.from(raw));
  }
  return _telemetryPropertiesFromMap(defaultValue);
}

TelemetryRepositoryContractProperties _telemetryPropertiesFromMap(
  Map<Object?, Object?> rawMap,
) {
  final properties = <TelemetryRepositoryContractProperty>[];
  rawMap.forEach((key, value) {
    final property = _telemetryPropertyFromRaw(key, value);
    if (property != null) {
      properties.add(property);
    }
  });
  return TelemetryRepositoryContractProperties(properties);
}

TelemetryRepositoryContractProperty? _telemetryPropertyFromRaw(
  Object? rawKey,
  Object? rawValue,
) {
  final normalizedKey = rawKey?.toString().trim() ?? '';
  if (normalizedKey.isEmpty || rawValue == null) {
    return null;
  }
  final value = _telemetryPropertyValueFromRaw(rawValue);
  if (value == null) {
    return null;
  }
  return TelemetryRepositoryContractProperty(
    keyValue: telemetryRepoString(
      normalizedKey,
      defaultValue: '',
      isRequired: true,
    ),
    value: value,
  );
}

TelemetryRepositoryContractPropertyValue? _telemetryPropertyValueFromRaw(
  Object? rawValue,
) {
  if (rawValue == null) {
    return null;
  }
  if (rawValue is TelemetryRepositoryContractPropertyValue) {
    return rawValue;
  }
  if (rawValue is TelemetryRepositoryContractProperties) {
    return TelemetryRepositoryContractPropertyValue.object(rawValue);
  }
  if (rawValue is TelemetryRepositoryContractTextValue) {
    return TelemetryRepositoryContractPropertyValue.text(rawValue);
  }
  if (rawValue is TelemetryRepositoryContractBoolValue) {
    return TelemetryRepositoryContractPropertyValue.boolean(rawValue);
  }
  if (rawValue is TelemetryRepositoryContractIntValue) {
    return TelemetryRepositoryContractPropertyValue.integer(rawValue);
  }
  if (rawValue is TelemetryRepositoryContractDoubleValue) {
    return TelemetryRepositoryContractPropertyValue.decimal(rawValue);
  }
  if (rawValue is String) {
    return TelemetryRepositoryContractPropertyValue.text(
      telemetryRepoString(
        rawValue,
        defaultValue: '',
        isRequired: false,
      ),
    );
  }
  if (rawValue is bool) {
    return TelemetryRepositoryContractPropertyValue.boolean(
      telemetryRepoBool(
        rawValue,
        defaultValue: false,
        isRequired: false,
      ),
    );
  }
  if (rawValue is int) {
    return TelemetryRepositoryContractPropertyValue.integer(
      telemetryRepoInt(
        rawValue,
        defaultValue: 0,
        isRequired: false,
      ),
    );
  }
  if (rawValue is num) {
    return TelemetryRepositoryContractPropertyValue.decimal(
      telemetryRepoDouble(
        rawValue.toDouble(),
        defaultValue: 0,
        isRequired: false,
      ),
    );
  }
  if (rawValue is DateTime) {
    return TelemetryRepositoryContractPropertyValue.text(
      telemetryRepoString(
        rawValue.toIso8601String(),
        defaultValue: '',
        isRequired: false,
      ),
    );
  }
  if (rawValue is Map) {
    return TelemetryRepositoryContractPropertyValue.object(
      _telemetryPropertiesFromMap(Map<Object?, Object?>.from(rawValue)),
    );
  }
  if (rawValue is Iterable) {
    final items = rawValue
        .map(_telemetryPropertyValueFromRaw)
        .whereType<TelemetryRepositoryContractPropertyValue>()
        .toList();
    return TelemetryRepositoryContractPropertyValue.list(items);
  }
  return TelemetryRepositoryContractPropertyValue.text(
    telemetryRepoString(
      rawValue.toString(),
      defaultValue: '',
      isRequired: false,
    ),
  );
}

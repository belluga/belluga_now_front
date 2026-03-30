import 'package:belluga_now/domain/repositories/telemetry_repository_contract_properties.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract_property_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';

class TelemetryPropertiesCodec {
  static Map<String, Object?> toRawMap(
    TelemetryRepositoryContractProperties? properties,
  ) {
    if (properties == null) {
      return const <String, Object?>{};
    }
    return Map<String, Object?>.unmodifiable(
      <String, Object?>{
        for (final property in properties.properties)
          property.keyValue.value: _toRawValue(property.value),
      },
    );
  }

  static TelemetryRepositoryContractProperties? merge({
    TelemetryRepositoryContractProperties? properties,
    TelemetryRepositoryContractProperties? screenContext,
    TelemetryRepositoryContractProperties? locationContext,
  }) {
    final merged = <String, Object?>{};
    final propertiesMap = toRawMap(properties);
    if (screenContext != null && !propertiesMap.containsKey('screen_context')) {
      merged['screen_context'] = toRawMap(screenContext);
    }
    if (locationContext != null &&
        !propertiesMap.containsKey('location_context')) {
      merged['location_context'] = toRawMap(locationContext);
    }
    merged.addAll(propertiesMap);
    if (merged.isEmpty) {
      return null;
    }
    return telemetryRepoMap(merged);
  }

  static String? readString(
    TelemetryRepositoryContractProperties? properties,
    String key,
  ) {
    final value = toRawMap(properties)[key];
    return value is String ? value : null;
  }

  static Object? _toRawValue(TelemetryRepositoryContractPropertyValue value) {
    if (value.textValue != null) {
      return value.textValue!.value;
    }
    if (value.boolValue != null) {
      return value.boolValue!.value;
    }
    if (value.intValue != null) {
      return value.intValue!.value;
    }
    if (value.doubleValue != null) {
      return value.doubleValue!.value;
    }
    if (value.objectValue != null) {
      return toRawMap(value.objectValue);
    }
    if (value.listValue != null) {
      return List<Object?>.unmodifiable(
        value.listValue!.map(_toRawValue),
      );
    }
    return null;
  }
}

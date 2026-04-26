import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ProximityPreferenceOptionalTextValue extends GenericStringValue {
  ProximityPreferenceOptionalTextValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  factory ProximityPreferenceOptionalTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = ProximityPreferenceOptionalTextValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    value.parse(raw?.toString() ?? '');
    return value;
  }

  String? get nullableValue {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

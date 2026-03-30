import 'package:value_object_pattern/value_object.dart';

class TelemetryRepositoryContractIntValue extends ValueObject<int> {
  TelemetryRepositoryContractIntValue({
    super.defaultValue = 0,
    super.isRequired = false,
  });

  factory TelemetryRepositoryContractIntValue.fromRaw(
    Object? raw, {
    int defaultValue = 0,
    bool isRequired = false,
  }) {
    final value = TelemetryRepositoryContractIntValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is int) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  int doParse(String? parseValue) {
    final parsed = int.tryParse((parseValue ?? '').trim());
    if (parsed == null) {
      return defaultValue;
    }
    return parsed;
  }
}

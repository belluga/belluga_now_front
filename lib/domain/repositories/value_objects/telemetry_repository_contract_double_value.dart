import 'package:value_object_pattern/value_object.dart';

class TelemetryRepositoryContractDoubleValue extends ValueObject<double> {
  TelemetryRepositoryContractDoubleValue({
    super.defaultValue = 0,
    super.isRequired = false,
  });

  factory TelemetryRepositoryContractDoubleValue.fromRaw(
    Object? raw, {
    double defaultValue = 0,
    bool isRequired = false,
  }) {
    final value = TelemetryRepositoryContractDoubleValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is num) {
      value.set(raw.toDouble());
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  double doParse(String? parseValue) {
    final parsed = double.tryParse((parseValue ?? '').trim());
    if (parsed == null) {
      return defaultValue;
    }
    return parsed;
  }
}

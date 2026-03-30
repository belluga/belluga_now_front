import 'package:value_object_pattern/value_object.dart';

class ScheduleRepositoryContractDoubleValue extends ValueObject<double> {
  ScheduleRepositoryContractDoubleValue({
    super.defaultValue = 0,
    super.isRequired = false,
  });

  factory ScheduleRepositoryContractDoubleValue.fromRaw(
    Object? raw, {
    double defaultValue = 0,
    bool isRequired = false,
  }) {
    final value = ScheduleRepositoryContractDoubleValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is double) {
      value.set(raw);
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

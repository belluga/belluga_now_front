import 'package:value_object_pattern/value_object.dart';

class ScheduleRepositoryContractDateTimeValue extends ValueObject<DateTime> {
  ScheduleRepositoryContractDateTimeValue({
    required super.defaultValue,
    super.isRequired = true,
  });

  factory ScheduleRepositoryContractDateTimeValue.fromRaw(
    Object? raw, {
    DateTime? defaultValue,
    bool isRequired = true,
  }) {
    final effectiveDefault =
        defaultValue ?? DateTime.fromMillisecondsSinceEpoch(0);
    final value = ScheduleRepositoryContractDateTimeValue(
      defaultValue: effectiveDefault,
      isRequired: isRequired,
    );
    if (raw is DateTime) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  DateTime doParse(dynamic parseValue) {
    if (parseValue is DateTime) {
      return parseValue;
    }
    final parsed = DateTime.tryParse((parseValue ?? '').toString().trim());
    if (parsed == null) {
      return defaultValue;
    }
    return parsed;
  }
}

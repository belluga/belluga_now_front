import 'package:value_object_pattern/value_object.dart';

class TimezoneServiceContractDateTimeValue extends ValueObject<DateTime> {
  TimezoneServiceContractDateTimeValue({
    required DateTime defaultValue,
    super.isRequired = true,
  }) : super(defaultValue: defaultValue);

  factory TimezoneServiceContractDateTimeValue.fromRaw(
    Object? raw, {
    DateTime? defaultValue,
    bool isRequired = true,
  }) {
    final effectiveDefault =
        defaultValue ?? DateTime.fromMillisecondsSinceEpoch(0);
    final value = TimezoneServiceContractDateTimeValue(
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

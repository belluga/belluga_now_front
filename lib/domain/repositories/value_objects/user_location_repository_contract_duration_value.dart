import 'package:value_object_pattern/value_object.dart';

class UserLocationRepositoryContractDurationValue extends ValueObject<Duration> {
  UserLocationRepositoryContractDurationValue({
    super.defaultValue = const Duration(seconds: 30),
    super.isRequired = true,
  });

  factory UserLocationRepositoryContractDurationValue.fromRaw(
    Object? raw, {
    Duration defaultValue = const Duration(seconds: 30),
  }) {
    final value = UserLocationRepositoryContractDurationValue(
      defaultValue: defaultValue,
      isRequired: true,
    );
    if (raw is Duration) {
      value.parse('${raw.inSeconds}');
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  Duration doParse(dynamic parseValue) {
    if (parseValue is Duration) {
      return parseValue;
    }
    if (parseValue is int) {
      return Duration(seconds: parseValue);
    }
    if (parseValue is String) {
      final normalized = parseValue.trim();
      final asInt = int.tryParse(normalized);
      if (asInt != null) {
        return Duration(seconds: asInt);
      }
    }
    return defaultValue;
  }
}

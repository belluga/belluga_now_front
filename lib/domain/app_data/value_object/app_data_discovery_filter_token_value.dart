import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AppDataDiscoveryFilterTokenValue extends GenericStringValue {
  AppDataDiscoveryFilterTokenValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory AppDataDiscoveryFilterTokenValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
  }) {
    final value = AppDataDiscoveryFilterTokenValue(
      defaultValue: defaultValue,
    );
    value.parse(raw is String ? raw.trim() : null);
    return value;
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}

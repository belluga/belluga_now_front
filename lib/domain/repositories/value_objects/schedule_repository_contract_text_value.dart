import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ScheduleRepositoryContractTextValue extends GenericStringValue {
  ScheduleRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory ScheduleRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = ScheduleRepositoryContractTextValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    final normalized = (raw as String?)?.trim();
    value.parse(normalized);
    return value;
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}

import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class UserEventsRepositoryContractTextValue extends GenericStringValue {
  UserEventsRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.maxLenght,
    super.minLenght,
  });

  factory UserEventsRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = true,
  }) {
    final value = UserEventsRepositoryContractTextValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    value.parse(raw?.toString());
    return value;
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}

import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AuthRepositoryContractTextValue extends GenericStringValue {
  AuthRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.maxLenght,
    super.minLenght,
  });

  factory AuthRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = true,
  }) {
    final value = AuthRepositoryContractTextValue(
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

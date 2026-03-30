import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class UserLocationRepositoryContractTextValue extends GenericStringValue {
  UserLocationRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.minLenght = 0,
  });

  factory UserLocationRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = UserLocationRepositoryContractTextValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
      minLenght: 0,
    );
    value.parse(raw?.toString() ?? '');
    return value;
  }
}

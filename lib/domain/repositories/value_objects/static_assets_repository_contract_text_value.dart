import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class StaticAssetsRepositoryContractTextValue extends GenericStringValue {
  StaticAssetsRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory StaticAssetsRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = StaticAssetsRepositoryContractTextValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    value.parse((raw as String?)?.trim());
    return value;
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}

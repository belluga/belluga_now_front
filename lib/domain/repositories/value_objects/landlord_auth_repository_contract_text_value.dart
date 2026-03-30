import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class LandlordAuthRepositoryContractTextValue extends GenericStringValue {
  LandlordAuthRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.maxLenght,
    super.minLenght,
  });

  factory LandlordAuthRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = true,
  }) {
    final value = LandlordAuthRepositoryContractTextValue(
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

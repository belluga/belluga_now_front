import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class DiscoveryFiltersRepositoryContractTextValue extends GenericStringValue {
  DiscoveryFiltersRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory DiscoveryFiltersRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = DiscoveryFiltersRepositoryContractTextValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    value.parse(raw?.toString().trim());
    return value;
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}

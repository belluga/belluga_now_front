import 'package:value_object_pattern/value_object.dart';

class AssetPathValue extends ValueObject<String> {
  AssetPathValue({
    super.defaultValue = '',
    super.isRequired = true,
  });

  @override
  String doParse(String? parseValue) => parseValue ?? defaultValue;
}

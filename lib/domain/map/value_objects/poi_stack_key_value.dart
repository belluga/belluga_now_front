import 'package:value_object_pattern/value_object.dart';

class PoiStackKeyValue extends ValueObject<String> {
  PoiStackKeyValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  @override
  String doParse(String? parseValue) => (parseValue ?? defaultValue).trim();
}

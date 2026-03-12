import 'package:value_object_pattern/value_object.dart';

class PoiReferenceIdValue extends ValueObject<String> {
  PoiReferenceIdValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  @override
  String doParse(String? parseValue) => (parseValue ?? defaultValue).trim();
}

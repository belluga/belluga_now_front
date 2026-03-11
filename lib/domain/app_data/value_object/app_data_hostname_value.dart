import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AppDataHostnameValue extends GenericStringValue {
  AppDataHostnameValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 1,
  });

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim().toLowerCase();
}

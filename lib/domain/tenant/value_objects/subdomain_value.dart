import 'package:slugify/slugify.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class SubdomainValue extends GenericStringValue {
  SubdomainValue({
    super.isRequired = true,
  });

  @override
  String doParse(String? parseValue) {
    return slugify(parseValue!);
  }
}

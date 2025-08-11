import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class DomainValue extends URIValue {
  DomainValue({
    super.defaultValue,
    super.isRequired = true,
  });
}
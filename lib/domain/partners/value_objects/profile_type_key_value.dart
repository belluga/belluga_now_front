import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ProfileTypeKeyValue extends GenericStringValue {
  ProfileTypeKeyValue([String raw = ''])
    : super(defaultValue: '', isRequired: false) {
    parse(raw.trim());
  }
}

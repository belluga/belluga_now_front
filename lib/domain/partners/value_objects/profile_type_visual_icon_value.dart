import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ProfileTypeVisualIconValue extends GenericStringValue {
  ProfileTypeVisualIconValue([String raw = ''])
      : super(defaultValue: '', isRequired: true) {
    parse(raw.trim());
  }
}

import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AccountProfileTypeValue extends GenericStringValue {
  AccountProfileTypeValue([String raw = ''])
    : super(defaultValue: '', isRequired: false) {
    parse(raw.trim());
  }
}

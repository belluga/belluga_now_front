import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AccountProfileTextValue extends GenericStringValue {
  AccountProfileTextValue([String raw = ''])
    : super(defaultValue: '', isRequired: false) {
    parse(raw.trim());
  }
}

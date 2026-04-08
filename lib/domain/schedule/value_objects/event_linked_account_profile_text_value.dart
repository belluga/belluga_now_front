import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class EventLinkedAccountProfileTextValue extends GenericStringValue {
  EventLinkedAccountProfileTextValue([String raw = ''])
    : super(defaultValue: '', isRequired: false) {
    parse(raw.trim());
  }
}

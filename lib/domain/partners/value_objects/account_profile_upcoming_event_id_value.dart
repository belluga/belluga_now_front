import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AccountProfileUpcomingEventIdValue extends GenericStringValue {
  AccountProfileUpcomingEventIdValue([String raw = ''])
    : super(defaultValue: '', isRequired: false) {
    parse(raw.trim());
  }
}

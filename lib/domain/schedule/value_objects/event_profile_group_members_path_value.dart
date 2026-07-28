import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class EventProfileGroupMembersPathValue extends GenericStringValue {
  EventProfileGroupMembersPathValue([String raw = ''])
    : super(defaultValue: '', isRequired: false) {
    parse(raw.trim());
  }

  String? get nullableValue {
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}

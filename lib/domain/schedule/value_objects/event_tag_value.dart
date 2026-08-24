import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class EventTagValue extends GenericStringValue {
  EventTagValue([
    Object? raw,
  ]) : super(defaultValue: '', isRequired: false, minLenght: 0) {
    parse(raw?.toString());
  }

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();
}

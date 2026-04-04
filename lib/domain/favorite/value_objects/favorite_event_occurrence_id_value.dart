import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class FavoriteEventOccurrenceIdValue extends GenericStringValue {
  FavoriteEventOccurrenceIdValue([String raw = ''])
    : super(defaultValue: '', isRequired: false) {
    parse(raw.trim());
  }
}

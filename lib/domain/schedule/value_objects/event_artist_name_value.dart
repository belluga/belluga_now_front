import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class EventArtistNameValue extends GenericStringValue {
  EventArtistNameValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 2,
  });
}

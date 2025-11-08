import 'package:value_object_pattern/value_object.dart';

class ArtistIsHighlightValue extends ValueObject<bool> {
  ArtistIsHighlightValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  @override
  bool doParse(String? parseValue) {
    if (parseValue == null) {
      return false;
    }
    final normalized = parseValue.toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    return false;
  }
}

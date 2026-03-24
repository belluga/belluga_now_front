import 'package:value_object_pattern/value_object.dart';

class InviteOccurrenceIdValue extends ValueObject<String?> {
  InviteOccurrenceIdValue({
    super.defaultValue,
    super.isRequired = false,
  });

  @override
  String? doParse(String? parseValue) {
    final value = parseValue?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}

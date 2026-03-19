import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class InviteAcceptedAtValue extends ValueObject<DateTime?> {
  InviteAcceptedAtValue({
    super.defaultValue,
    super.isRequired = false,
  });

  @override
  DateTime? doParse(String? parseValue) {
    final value = parseValue?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw InvalidValueException();
    }
    return parsed;
  }
}

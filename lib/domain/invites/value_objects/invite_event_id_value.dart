import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class InviteEventIdValue extends ValueObject<String> {
  InviteEventIdValue({
    super.defaultValue = '',
    super.isRequired = true,
  });

  @override
  String doParse(String? parseValue) {
    final value = parseValue?.trim();
    if (value == null || value.isEmpty) {
      throw InvalidValueException();
    }
    return value;
  }
}

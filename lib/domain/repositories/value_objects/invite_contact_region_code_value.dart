import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class InviteContactRegionCodeValue extends ValueObject<String> {
  InviteContactRegionCodeValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  @override
  String doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toUpperCase();
    if (normalized.isEmpty) {
      if (isRequired) {
        throw InvalidValueException();
      }
      return '';
    }
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
      throw InvalidValueException();
    }
    return normalized;
  }
}

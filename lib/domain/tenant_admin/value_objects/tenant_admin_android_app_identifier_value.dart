import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminAndroidAppIdentifierValue extends ValueObject<String> {
  TenantAdminAndroidAppIdentifierValue({
    super.defaultValue = '',
    super.isRequired = true,
  });

  static final RegExp _pattern = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
  );

  @override
  String doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim();
    if (!_pattern.hasMatch(normalized)) {
      throw InvalidValueException();
    }
    return normalized;
  }
}

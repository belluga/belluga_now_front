import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminHexColorValue extends ValueObject<String> {
  TenantAdminHexColorValue({
    super.defaultValue = '#000000',
    super.isRequired = true,
  });

  static final RegExp _hexPattern = RegExp(r'^#[0-9A-F]{6}$');

  @override
  String doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toUpperCase();
    if (!_hexPattern.hasMatch(normalized)) {
      throw InvalidValueException();
    }
    return normalized;
  }
}

import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminSha256FingerprintValue extends ValueObject<String> {
  TenantAdminSha256FingerprintValue({
    super.defaultValue = '',
    super.isRequired = true,
  });

  static final RegExp _pattern = RegExp(r'^([A-F0-9]{2}:){31}[A-F0-9]{2}$');

  @override
  String doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toUpperCase();
    if (!_pattern.hasMatch(normalized)) {
      throw InvalidValueException();
    }
    return normalized;
  }
}

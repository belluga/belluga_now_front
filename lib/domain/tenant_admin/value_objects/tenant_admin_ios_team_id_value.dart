import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminIosTeamIdValue extends ValueObject<String> {
  TenantAdminIosTeamIdValue({
    super.defaultValue = '',
    super.isRequired = true,
  });

  static final RegExp _pattern = RegExp(r'^[A-Z0-9]{10}$');

  @override
  String doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toUpperCase();
    if (!_pattern.hasMatch(normalized)) {
      throw InvalidValueException();
    }
    return normalized;
  }
}

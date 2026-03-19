import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminIosBundleIdentifierValue extends ValueObject<String> {
  TenantAdminIosBundleIdentifierValue({
    super.defaultValue = '',
    super.isRequired = true,
  });

  static final RegExp _pattern = RegExp(
    r'^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$',
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

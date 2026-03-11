import 'package:value_object_pattern/value_object.dart';

class TenantAdminOptionalTextValue extends ValueObject<String> {
  TenantAdminOptionalTextValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();

  String? get nullableValue {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

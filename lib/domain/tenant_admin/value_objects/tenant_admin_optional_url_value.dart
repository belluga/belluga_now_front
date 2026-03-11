import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminOptionalUrlValue extends ValueObject<String> {
  TenantAdminOptionalUrlValue({
    super.defaultValue = '',
    super.isRequired = false,
  });

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();

  @override
  void validate(String? newValue) {
    final normalized = (newValue ?? '').trim();
    if (normalized.isEmpty) {
      if (isRequired) {
        throw RequiredValueException();
      }
      return;
    }

    final parsed = Uri.tryParse(normalized);
    if (parsed == null || !parsed.hasScheme || parsed.host.trim().isEmpty) {
      throw InvalidValueException();
    }
  }

  String? get nullableValue {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

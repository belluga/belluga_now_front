import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminDomainStatusValue extends ValueObject<String> {
  TenantAdminDomainStatusValue({
    super.defaultValue = active,
    super.isRequired = true,
  });

  static const String active = 'active';
  static const String deleted = 'deleted';

  @override
  String doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    if (normalized == active || normalized == deleted) {
      return normalized;
    }
    throw InvalidValueException();
  }
}

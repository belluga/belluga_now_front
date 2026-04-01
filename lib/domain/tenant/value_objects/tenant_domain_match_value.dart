import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantDomainMatchValue extends ValueObject<bool> {
  TenantDomainMatchValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  @override
  bool doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
    throw InvalidValueException();
  }
}

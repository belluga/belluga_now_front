import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminDateTimeValue extends ValueObject<DateTime> {
  TenantAdminDateTimeValue(DateTime raw)
      : super(defaultValue: raw, isRequired: true) {
    set(raw);
  }

  @override
  DateTime doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim();
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      throw InvalidValueException();
    }
    return parsed;
  }
}

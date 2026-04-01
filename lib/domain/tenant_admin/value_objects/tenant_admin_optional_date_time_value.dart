import 'package:value_object_pattern/value_object.dart';

class TenantAdminOptionalDateTimeValue extends ValueObject<DateTime?> {
  TenantAdminOptionalDateTimeValue([DateTime? raw])
      : super(defaultValue: raw, isRequired: false) {
    set(raw);
  }

  @override
  DateTime? doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return DateTime.tryParse(normalized);
  }
}

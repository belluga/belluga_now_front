import 'package:value_object_pattern/value_object.dart';

final class TenantAdminAccountProfileExternalLinksLimitValue
    extends ValueObject<int> {
  TenantAdminAccountProfileExternalLinksLimitValue(int raw)
    : super(defaultValue: 0, isRequired: true) {
    parse(raw.toString());
  }

  @override
  int doParse(String? parseValue) {
    final parsed = int.tryParse(parseValue ?? '') ?? 0;
    return parsed < 0 ? 0 : parsed;
  }
}

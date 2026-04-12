import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class TenantAdminAccountProfileIdValue extends GenericStringValue {
  TenantAdminAccountProfileIdValue([String raw = ''])
      : super(defaultValue: '', isRequired: true, minLenght: 1) {
    parse(raw);
  }
}

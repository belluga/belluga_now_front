import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AccountProfileContactChannelIdValue extends GenericStringValue {
  AccountProfileContactChannelIdValue([String raw = ''])
    : super(defaultValue: '', isRequired: true, minLenght: 1) {
    if (raw.trim().isNotEmpty) {
      parse(raw);
    }
  }
}

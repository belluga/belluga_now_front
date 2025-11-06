import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';

class AuthEmailAddressValue extends EmailAddressValue {
  AuthEmailAddressValue({
    super.defaultValue = "",
    super.isRequired = true,
  });
}

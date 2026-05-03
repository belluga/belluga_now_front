import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AuthPhoneOtpDeliveryChannelValue extends GenericStringValue {
  AuthPhoneOtpDeliveryChannelValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 1,
  });
}

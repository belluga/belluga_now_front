import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_challenge_id_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_delivery_channel_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';

final class AuthPhoneOtpChallenge {
  AuthPhoneOtpChallenge({
    required this.challengeIdValue,
    required this.phoneValue,
    required this.deliveryChannelValue,
    DomainOptionalDateTimeValue? expiresAtValue,
    DomainOptionalDateTimeValue? resendAvailableAtValue,
  })  : expiresAtValue = expiresAtValue ?? DomainOptionalDateTimeValue(),
        resendAvailableAtValue =
            resendAvailableAtValue ?? DomainOptionalDateTimeValue();

  final AuthPhoneOtpChallengeIdValue challengeIdValue;
  final AuthPhoneOtpPhoneValue phoneValue;
  final AuthPhoneOtpDeliveryChannelValue deliveryChannelValue;
  final DomainOptionalDateTimeValue expiresAtValue;
  final DomainOptionalDateTimeValue resendAvailableAtValue;

  String get challengeId => challengeIdValue.value;
  String get phone => phoneValue.value;
  String get deliveryChannel => deliveryChannelValue.value;
  DateTime? get expiresAt => expiresAtValue.value;
  DateTime? get resendAvailableAt => resendAvailableAtValue.value;
}

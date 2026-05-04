import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';

class PhoneOtpVerificationResponse {
  const PhoneOtpVerificationResponse({
    required this.user,
    required this.token,
    this.userId,
    this.identityState,
  });

  final UserDto user;
  final String token;
  final String? userId;
  final String? identityState;
}

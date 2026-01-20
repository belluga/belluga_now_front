import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';

class AnonymousIdentityResponse {
  const AnonymousIdentityResponse({
    required this.token,
    this.userId,
    this.identityState,
    this.expiresAt,
  });

  final String token;
  final String? userId;
  final String? identityState;
  final String? expiresAt;
}

class AuthRegistrationResponse {
  const AuthRegistrationResponse({
    required this.token,
    this.userId,
    this.identityState,
    this.expiresAt,
  });

  final String token;
  final String? userId;
  final String? identityState;
  final String? expiresAt;
}

abstract class AuthBackendContract {
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  );
  Future<void> logout();
  Future<UserDto> loginCheck();
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  });
  Future<AnonymousIdentityResponse> issueAnonymousIdentity({
    required String deviceName,
    required String fingerprintHash,
    String? userAgent,
    String? locale,
    Map<String, dynamic>? metadata,
  });
}

export 'anonymous_identity_response.dart';
export 'auth_registration_response.dart';

import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/anonymous_identity_response.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_registration_response.dart';

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

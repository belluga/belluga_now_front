import 'package:belluga_now/domain/auth/errors/belluga_auth_errors.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';

class MockAuthBackend extends AuthBackendContract {
  static const String _mockUserId = '507f1f77bcf86cd799439011';
  static const String _mockPassword = '765432e1';
  static const String _mockToken = 'mock-token';

  UserDto get _mockUser => UserDto(
        id: _mockUserId,
        profile: UserProfileDto(
          name: 'John Doe',
          email: 'email@mock.com',
          birthday: '',
          pictureUrl: 'https://example.com/avatar.png',
        ),
        customData: const {},
      );

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    if (password == _mockPassword && email == _mockUser.profile.email) {
      return (_mockUser, _mockToken);
    }

    throw BellugaAuthError.fromCode(
      errorCode: 403,
      message: 'As credenciais fornecidas estão incorretas.',
    );
  }

  @override
  Future<UserDto> loginCheck() async => _mockUser;

  @override
  Future<void> logout() async {}

  @override
  Future<AnonymousIdentityResponse> issueAnonymousIdentity({
    required String deviceName,
    required String fingerprintHash,
    String? userAgent,
    String? locale,
    Map<String, dynamic>? metadata,
  }) async {
    return const AnonymousIdentityResponse(
      token: _mockToken,
      userId: _mockUserId,
      identityState: 'anonymous',
    );
  }

  @override
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  }) async {
    return const AuthRegistrationResponse(
      token: _mockToken,
      userId: _mockUserId,
      identityState: 'authenticated',
    );
  }
}

import 'package:belluga_now/domain/auth/errors/belluga_auth_errors.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/helpers/mock_functions.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/auth_backend/auth_backend.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';

class MockAuthBackend extends AuthBackendContract with MockFunctions {
  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    if (password == _fakePassword && email == _mockUser.profile.email) {
      final _token = "123";
      return (_mockUser, _token);
    }

    throw BellugaAuthError.fromCode(
      errorCode: 403,
      message: "As credenciais fornecidas estão incorretas.",
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
    try {
      return await LaravelAuthBackend().issueAnonymousIdentity(
        deviceName: deviceName,
        fingerprintHash: fingerprintHash,
        userAgent: userAgent,
        locale: locale,
        metadata: metadata,
      );
    } catch (_) {
      return AnonymousIdentityResponse(
        token: 'anon-token-$fakeMongoId',
        userId: fakeMongoId,
        identityState: 'anonymous',
      );
    }
  }

  String get _fakePassword => "765432e1";

  UserDto get _mockUser => UserDto(
        id: fakeMongoId,
        profile: UserProfileDto(
          name: "John Doe",
          email: "email@mock.com",
          birthday: "",
          pictureUrl: "https://example.com/avatar.png",
        ),
        customData: {},
      );
}

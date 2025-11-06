import 'package:belluga_now/domain/auth/errors/belluga_auth_errors.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/mock_backend/helpers/mock_functions.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/user_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/user_profile_dto.dart';

class MockAuthBackend extends AuthBackendContract with MockFunctions {
  @override
  Future<(UserDTO, String)> loginWithEmailPassword(
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
  Future<UserDTO> loginCheck() async => _mockUser;

  @override
  Future<void> logout() async {}

  String get _fakePassword => "765432e1";

  UserDTO get _mockUser => UserDTO(
        id: fakeMongoId,
        profile: UserProfileDTO(
          firstName: "John",
          lastName: "Doe",
          name: "John Doe",
          email: "email@mock.com",
          gender: "Masculino",
          birthday: "",
          pictureUrl: "https://example.com/avatar.png",
        ),
      );
}

import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';

abstract class AuthBackendContract {
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  );
  Future<void> logout();
  Future<UserDto> loginCheck();
}

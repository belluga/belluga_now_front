import 'package:belluga_now/infrastructure/services/dal/dto/user_dto.dart';

abstract class AuthBackendContract {
  Future<(UserDTO, String)> loginWithEmailPassword(
    String email,
    String password,
  );
  Future<void> logout();
  Future<UserDTO> loginCheck();
}

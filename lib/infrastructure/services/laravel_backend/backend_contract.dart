import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/user_dto.dart';

abstract class BackendContract {
  Future<(UserDTO, String)> loginWithEmailPassword(String email, String password);
  Future<void> logout();
  Future<UserDTO> loginCheck();
}
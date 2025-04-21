import 'package:dio/dio.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/belluga_constants.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/user/user_belluga.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/user_dto.dart';

final class AuthRepository extends AuthRepositoryContract<UserBelluga> {

  final dio = Dio();
  
  @override
  bool get isUserLoggedIn {
    return userStreamValue.value != null;
  }

  @override
  bool get isAuthorized {
    return userStreamValue.value != null;
  }

  @override
  Future<void> init() {
    throw UnimplementedError();
  }

  @override
  Future<UserBelluga?> loginWithEmailPassword(String email, String password) async{

    final response = await dio.post(
      BellugaConstants.api.login,
      data: {
        "email": email,
        "password": password,
        "device_name": BellugaConstants.settings.platform,
      }
    );

    print("response.data");
  

    final userDTO = UserDTO.fromMap(response.data["data"]["user"]);

    final user = UserBelluga.fromDTO(userDTO);

    userStreamValue.addValue(user);

    print(user);

    return Future.value(user);
  }

  @override
  Future<void> signUpWithEmailPassword(String email, String password){
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email){
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(Map<String, Object?> data){
    throw UnimplementedError();
  }

}

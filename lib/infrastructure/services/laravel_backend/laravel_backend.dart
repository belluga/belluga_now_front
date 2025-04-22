import 'package:dio/dio.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/belluga_constants.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/tenant/tenant.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/user_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';

class LaravelBackend extends BackendContract {
  final dio = Dio();

  AuthRepositoryContract get authRepository =>
      GetIt.I.get<AuthRepositoryContract>();

  @override
  Future<(UserDTO, String)> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    final response = await dio.post(
      BellugaConstants.api.baseUrl + _Paths.login,
      data: {
        "email": email,
        "password": password,
        "device_name": GetIt.I.get<Tenant>().device,
      },
    );

    final userDTO = UserDTO.fromMap(response.data["data"]["user"]);
    final token = response.data["data"]["token"];

    if (token is! String) {
      throw Exception("Error generating access token.");
    }

    return (userDTO, token);
  }

  @override
  Future<UserDTO> loginCheck() async {
    final response = await dio.post(
      BellugaConstants.api.baseUrl + _Paths.loginCheck,
      options: Options(headers: _getHeaders()),
    );

    return UserDTO.fromMap(response.data["data"]["user"]);
  }

  @override
  Future<void> logout() async {
    await dio.post(
      BellugaConstants.api.baseUrl + _Paths.logout,
      data: {
        "device": GetIt.I.get<Tenant>().device
      },
      options: Options(headers: _getHeaders()),
    );
  }

  Map<String, dynamic> _getHeaders() {
    final token = authRepository.userToken;

    return {
      Headers.contentTypeHeader: Headers.jsonContentType,
      Headers.acceptHeader: Headers.jsonContentType,
      "Authorization": "Bearer $token",
    };
  }
}

class _Paths {
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String loginCheck = '/auth/check';
}

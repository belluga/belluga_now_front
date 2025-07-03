import 'package:dio/dio.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/belluga_constants.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/auth/errors/belluga_auth_errors.dart';
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

    try{
      final response = await dio.post(
        BellugaConstants.api.baseUrl + _Paths.login,
        data: {
          "email": email,
          "password": password,
          "device_name": GetIt.I.get<Tenant>().device,
        },
        options: Options(headers: _getHeaders()),
      );

      final userDTO = UserDTO.fromMap(response.data["data"]["user"]);
      final String token = response.data["data"]["token"];

      return (userDTO, token);

    } on DioException catch (e) {

      String? errorMessage = e.response?.data["message"];
      final Map<String, dynamic> errors = e.response?.data["errors"];

      throw BellugaAuthError.fromCode(
        errorCode: e.response?.statusCode,
        message: errorMessage,
        errors: errors
      );

    } catch (e) {
      throw BellugaAuthError.fromCode();
    }
  }

  @override
  Future<UserDTO> loginCheck() async {
    final response = await dio.post(
      BellugaConstants.api.baseUrl + _Paths.loginCheck,
      options: Options(headers: _getAuthenticatedHeaders()),
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
      options: Options(headers: _getAuthenticatedHeaders()),
    );
  }

  Map<String, dynamic> _getHeaders() {
    return {
      Headers.contentTypeHeader: Headers.jsonContentType,
      Headers.acceptHeader: Headers.jsonContentType,
    };
  }

  Map<String, dynamic> _getAuthenticatedHeaders() {
    final token = authRepository.userToken;

    final baseHeader = _getHeaders();

    baseHeader["Authorization"] = "Bearer $token";

    return baseHeader;
  }
}

class _Paths {
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String loginCheck = '/auth/check';
}

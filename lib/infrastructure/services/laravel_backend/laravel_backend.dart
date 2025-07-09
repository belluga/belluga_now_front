import 'package:dio/dio.dart';
import 'package:unifast_portal/application/configurations/belluga_constants.dart';
import 'package:unifast_portal/domain/auth/errors/belluga_auth_errors.dart';
import 'package:unifast_portal/domain/repositories/auth_repository_contract.dart';
import 'package:unifast_portal/domain/tenant/tenant.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/external_course_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/user_dto.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/backend_contract.dart';
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
    try {
      final response = await dio.post(
        BellugaConstants.api.baseUrl + _Paths.login,
        data: {
          "email": email,
          "password": password,
          "device_name": GetIt.I.get<Tenant>().device,
        },
        options: Options(headers: _getHeaders()),
      );

      final userDTO = UserDTO.fromJson(response.data["data"]["user"]);
      final String token = response.data["data"]["token"];

      return (userDTO, token);
    } on DioException catch (e) {
      String? errorMessage = e.response?.data["message"];
      final Map<String, dynamic> errors = e.response?.data["errors"];

      throw BellugaAuthError.fromCode(
        errorCode: e.response?.statusCode,
        message: errorMessage,
        errors: errors,
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

    return UserDTO.fromJson(response.data["data"]["user"]);
  }

  @override
  Future<void> logout() async {
    await dio.post(
      BellugaConstants.api.baseUrl + _Paths.logout,
      data: {"device": GetIt.I.get<Tenant>().device},
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

  @override
  Future<List<ExternalCourseDTO>> getExternalCourses() async {
    //TODO: Implement this method to fetch the external courses summary.
    final response = await dio.post(
      BellugaConstants.api.baseUrl + _Paths.loginCheck,
      options: Options(headers: _getAuthenticatedHeaders()),
    );

    final _externalCourses = (response.data as List<Map<String, dynamic>>)
        .map((item) => ExternalCourseDTO.fromJson(item))
        .toList();

    return Future.value(_externalCourses);
  }

  @override
  Future<List<CourseDTO>> getMyCourses() async {
    //TODO: Implement this method to fetch courses summary.
    final response = await dio.post(
      BellugaConstants.api.baseUrl + _Paths.loginCheck,
      options: Options(headers: _getAuthenticatedHeaders()),
    );

    final _courses = response.data
        .map((item) => CourseDTO.fromJson(item))
        .toList();

    return Future.value(_courses);
  }

  //TODO: Implement this method to fetch course.
  @override
  Future<CourseItemDTO> courseItemGetDetails(String courseId) async {
    final response = await dio.get(
      '${BellugaConstants.api.baseUrl}/courses/$courseId',
      options: Options(headers: _getAuthenticatedHeaders()),
    );

    return CourseItemDTO.fromJson(response.data);
  }
}

class _Paths {
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String loginCheck = '/auth/check';
}

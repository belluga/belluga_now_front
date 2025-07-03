import 'package:dio/dio.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/auth/errors/belluga_auth_errors.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/external_courses_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/user_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/user_profile_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/laravel_backend/backend_contract.dart';
import 'package:get_it/get_it.dart';

class MockBackend extends BackendContract {
  final dio = Dio();

  AuthRepositoryContract get authRepository =>
      GetIt.I.get<AuthRepositoryContract>();

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

  @override
  Future<ExternalCoursesSummaryDTO> externalCoursesGetDashboardSummary() {
    return Future.value(
      ExternalCoursesSummaryDTO.fromMap(
        _externalCoursesGetDashboardSummaryResponse,
      ),
    );
  }

  String get _fakePassword => "765432e1";

  UserDTO get _mockUser => UserDTO(
    id: "6862af23bb2123c0d506289d",
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

  Map<String, dynamic> get _externalCoursesGetDashboardSummaryResponse => {
    "total": 2,
    "data": [
      {
        "id": "6864808e5a115a9591257e2c",
        "title": "Curso 1",
        "description": "Descrição do curso 1",
        "thumb_url": "https://picsum.photos/id/1/200/300",
        "platform_url": "https://example.com/course1.png",
        "initial_password": "765432e1",
      },
      {
        "id": "6864f4415a115a9591257e2d",
        "title": "Curso 1",
        "description": "Descrição do curso 1",
        "thumb_url": "https://picsum.photos/id/20/200/300",
        "platform_url": "https://example.com/course1.png",
        "initial_password": "765432e1",
      },
    ],
  };
}

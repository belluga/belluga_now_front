import 'package:dio/dio.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/auth/errors/belluga_auth_errors.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/external_courses_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_courses_summary_dto.dart';
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

  @override
  Future<MyCoursesSummaryDTO> myCoursesGetDashboardSummary() {
    return Future.value(
      MyCoursesSummaryDTO.fromMap(
        _myCoursesGetDashboardSummaryResponse,
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

  //TODO: Retrieve partner name and logo to place on the Course.
  Map<String, dynamic> get _externalCoursesGetDashboardSummaryResponse => {
    "total": 2,
    "data": [
      {
        "id": "6864808e5a115a9591257e2c",
        "title": "Graduação em Matemática",
        "description": "Curso de graduação em matemática.",
        "thumb_url": "https://picsum.photos/id/1/200/300",
        "platform_url": "https://example.com/course1.png",
        "initial_password": "765432e1",
      },
      {
        "id": "6864f4415a115a9591257e2d",
        "title": "Graduação em Belas Artes",
        "description": "Curso de graduação em Belas Artes.",
        "thumb_url": "https://picsum.photos/id/20/200/300",
        "platform_url": "https://example.com/course1.png",
        "initial_password": "765432e1",
      },
    ],
  };

  Map<String, dynamic> get _myCoursesGetDashboardSummaryResponse => {
    "total": 3,
    "data": [
      {
        "id": "6864808e5a115a9591257e2c",
        "title": "MBA em Ciências da Mente e Liderança Humanizada",
        "type": "MBA",
        "description": "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
        "thumb_url": "https://picsum.photos/id/30/200/300",
        "expert": {
          "name" : "Roberto Shinyashiki",
          "avatar_url": "https://picsum.photos/id/40/200/300",
        },
        "next_lesson": {
          "id": "6864808e5a115a9591257e2c",
          "title": "Introdução à Liderança Humanizada",
          "description": "Aprenda os fundamentos da liderança humanizada.",
          "thumb_url": "https://picsum.photos/id/60/200/300",
        },
      },
      {
        "id": "6864f4415a115a9591257e2d",
        "title": "Trilha Standup Comedy com Welber Rodrigues",
        "type": "Trilha Unifast",
        "description": "Michel Vitor compartilha sua experiência e técnicas de Standup Comedy, ajudando você a desenvolver suas habilidades humorísticas e demonstrando como criar uma persona alternativa e viver duas vidas paralelas.",
        "thumb_url": "https://picsum.photos/id/80/200/300",
        "expert": {
          "name" : "Michel Vitor",
          "avatar_url": "https://picsum.photos/id/90/200/300",
        },
        "next_lesson": {
          "id": "6864808e5a115a9591257e2c",
          "title": "Como criei Welber Rodrigues",
          "description": "Como criei minha persona alternativa.",
          "thumb_url": "https://picsum.photos/id/100/200/300",
        },
      },
      {
        "id": "6864f4415a115a9591257e2d",
        "title": "De Jovem Aprendiz a Estagiário de Sucesso",
        "type": "Trilha Unifast",
        "description": "Aprenda com a incrível trajetória de Lucas e encontrará dicas valiosas para se destacar no mercado de trabalho.",
        "thumb_url": "https://picsum.photos/id/110/200/300",
        "expert": {
          "name" : "Lucas Paifer",
          "avatar_url": "https://picsum.photos/id/120/200/300",
        },
        "next_lesson": {
          "id": "6864808e5a115a9591257e2c",
          "title": "A chave para a transição",
          "description": "Aqui você vai aprender o segredo para garantir uma transição sem sustos..",
          "thumb_url": "https://picsum.photos/id/130/200/300",
        },
      },
    ],
  };
}

import 'package:dio/dio.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/auth/errors/belluga_auth_errors.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_dto.dart';
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
      ExternalCoursesSummaryDTO.fromJson(
        _externalCoursesGetDashboardSummaryResponse,
      ),
    );
  }

  @override
  Future<MyCoursesSummaryDTO> myCoursesGetDashboardSummary() {
    return Future.value(
      MyCoursesSummaryDTO.fromJson(_myCoursesGetDashboardSummaryResponse),
    );
  }

  @override
  Future<CourseDTO> courseGetDetails(String courseId) async {
    if (courseId == "6864808e5a115a9591257e2c") {
      return CourseDTO.fromJson(_myCourses[0]);
    } else if (courseId == "6864f4415a115a9591257e2d") {
      return CourseDTO.fromJson(_myCourses[1]);
    } else {
      throw DioException(
        requestOptions: RequestOptions(path: ""),
        error: "Curso não encontrado",
      );
    }
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

  List<Map<String, dynamic>> get _myCourses => [
    {
      "id": "6864808e5a115a9591257e2c",
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {
        "id": "6864808e5a115a9591257e2d",
        "name": "MBA",
        "slug": "mba"
      },
      "description":
          "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/30/200/300"},
      },
      "categories": [
        {"id": "6864808e5a115a9591257e2c", "name": "Ciências da Mente"},
        {"id": "6864808e5a115a9591257e2d", "name": "Liderança"},
        {"id": "6864808e5a115a9591257e2d", "name": "Negócios"},
      ],
      "expert": {
        "id": "6864808e5a115a9591257e2c",
        "name": "Roberto Shinyashiki",
        "avatar_url": "https://picsum.photos/id/40/200/300",
      },
      "disciplines": {
        "summary": {"total": 10},
        "items": [
          {
            "id": "6864808e5a115a9591257e2c",
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "lessons": {
              "summary": {"total": 2},
              "items": [
                {
                  "id": "6864808e5a115a9591257e2c",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": "6864808e5a115a9591257e2d",
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
              ],
            },
          },
          {
            "id": "6864808e5a115a9591257e2c",
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "lessons": {
              "summary": {"total": 2},
              "items": [
                {
                  "id": "6864808e5a115a9591257e2c",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": "6864808e5a115a9591257e2d",
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
              ],
            },
          },
        ],
      },
    },
    {
      "id": "6864808e5a115a9591257e2c",
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {
        "id": "6864808e5a115a9591257e2d",
        "name": "MBA",
        "slug": "mba"
      },
      "description":
          "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/30/200/300"},
      },
      "categories": [
        {"id": "6864808e5a115a9591257e2c", "name": "Ciências da Mente"},
        {"id": "6864808e5a115a9591257e2d", "name": "Liderança"},
        {"id": "6864808e5a115a9591257e2d", "name": "Negócios"},
      ],
      "expert": {
        "id": "6864808e5a115a9591257e2c",
        "name": "Roberto Shinyashiki",
        "avatar_url": "https://picsum.photos/id/40/200/300",
      },
      "disciplines": {
        "summary": {"total": 10},
        "items": [
          {
            "id": "6864808e5a115a9591257e2c",
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "lessons": {
              "summary": {"total": 2},
              "items": [
                {
                  "id": "6864808e5a115a9591257e2c",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": "6864808e5a115a9591257e2d",
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
              ],
            },
          },
          {
            "id": "6864808e5a115a9591257e2c",
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "lessons": {
              "summary": {"total": 2},
              "items": [
                {
                  "id": "6864808e5a115a9591257e2c",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": "6864808e5a115a9591257e2d",
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
              ],
            },
          },
        ],
      },
    },
    {
      "id": "6864808e5a115a9591257e2c",
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {
        "id": "6864808e5a115a9591257e2d",
        "name": "Pós Graduação",
        "slug": "pos"
      },
      "description":
          "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/30/200/300"},
      },
      "categories": [
        {"id": "6864808e5a115a9591257e2c", "name": "Ciências da Mente"},
        {"id": "6864808e5a115a9591257e2d", "name": "Liderança"},
        {"id": "6864808e5a115a9591257e2d", "name": "Negócios"},
      ],
      "expert": {
        "id": "6864808e5a115a9591257e2c",
        "name": "Roberto Shinyashiki",
        "avatar_url": "https://picsum.photos/id/40/200/300",
      },
      "disciplines": {
        "summary": {"total": 10},
        "items": [
          {
            "id": "6864808e5a115a9591257e2c",
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "lessons": {
              "summary": {"total": 2},
              "items": [
                {
                  "id": "6864808e5a115a9591257e2c",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": "6864808e5a115a9591257e2d",
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
              ],
            },
          },
          {
            "id": "6864808e5a115a9591257e2c",
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "lessons": {
              "summary": {"total": 2},
              "items": [
                {
                  "id": "6864808e5a115a9591257e2c",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": "6864808e5a115a9591257e2d",
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url": "https://example.com/video.mp4",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    "html": {"content": "<p>Conteúdo em HTML</p>"},
                  },
                  "files": [
                    {
                      "url": "https://example.com/file.pdf",
                      "name": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
              ],
            },
          },
        ],
      },
    },
  ];

  //TODO: Retrieve partner name and logo to place on the Course.
  Map<String, dynamic> get _externalCoursesGetDashboardSummaryResponse => {
    "total": 2,
    "data": [
      {
        "id": "6864808e5a115a9591257e2c",
        "title": "Graduação em Matemática",
        "description": "Curso de graduação em matemática.",
        "thumb": {
          "type": "image",
          "data": {"url": "https://picsum.photos/id/30/200/300"},
        },
        "platform_url": "https://example.com/course1.png",
        "initial_password": "765432e1",
      },
      {
        "id": "6864f4415a115a9591257e2d",
        "title": "Graduação em Belas Artes",
        "description": "Curso de graduação em Belas Artes.",
        "thumb": {
          "type": "image",
          "data": {"url": "https://picsum.photos/id/30/200/300"},
        },
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
        "type": {
          "id": "6864808e5a115a9591257e2c",
          "name": "MBA",
          "slug": "mba",
        },
        "description":
            "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
        "thumb": {
          "type": "image",
          "data": {"url": "https://picsum.photos/id/30/200/300"},
        },
        "expert": {
          "name": "Roberto Shinyashiki",
          "avatar_url": "https://picsum.photos/id/40/200/300",
        },
        "next_lesson": {
          "id": "6864808e5a115a9591257e2c",
          "title": "Introdução à Liderança Humanizada",
          "description": "Aprenda os fundamentos da liderança humanizada.",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/30/200/300"},
          },
        },
      },
      {
        "id": "6864f4415a115a9591257e2d",
        "title": "Trilha Standup Comedy com Welber Rodrigues",
        "type": {
          "id": "6864808e5a115a9591257e2c",
          "name": "Trilhas Unifast",
          "slug": "unifast-tracks",
        },
        "description":
            "Michel Vitor compartilha sua experiência e técnicas de Standup Comedy, ajudando você a desenvolver suas habilidades humorísticas e demonstrando como criar uma persona alternativa e viver duas vidas paralelas.",
        "thumb": {
          "type": "image",
          "data": {"url": "https://picsum.photos/id/30/200/300"},
        },
        "expert": {
          "name": "Michel Vitor",
          "avatar_url": "https://picsum.photos/id/90/200/300",
        },
        "next_lesson": {
          "id": "6864808e5a115a9591257e2c",
          "title": "Como criei Welber Rodrigues",
          "description": "Como criei minha persona alternativa.",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/30/200/300"},
          },
        },
      },
      {
        "id": "6864f4415a115a9591257e2d",
        "title": "De Jovem Aprendiz a Estagiário de Sucesso",
        "type": {
          "id": "6864808e5a115a9591257e2c",
          "name": "Trilhas Unifast",
          "slug": "unifast-tracks",
        },
        "description":
            "Aprenda com a incrível trajetória de Lucas e encontrará dicas valiosas para se destacar no mercado de trabalho.",
        "thumb": {
          "type": "image",
          "data": {"url": "https://picsum.photos/id/30/200/300"},
        },
        "expert": {
          "name": "Lucas Paifer",
          "avatar_url": "https://picsum.photos/id/120/200/300",
        },
        "next_lesson": {
          "id": "6864808e5a115a9591257e2c",
          "title": "A chave para a transição",
          "description":
              "Aqui você vai aprender o segredo para garantir uma transição sem sustos..",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/30/200/300"},
          },
        },
      },
    ],
  };
}

import 'dart:math';

import 'package:dio/dio.dart';
import 'package:unifast_portal/domain/auth/errors/belluga_auth_errors.dart';
import 'package:unifast_portal/domain/repositories/auth_repository_contract.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/external_course_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/user_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/user_profile_dto.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/backend_contract.dart';
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
  Future<List<ExternalCourseDTO>> getExternalCourses() {
    final _externalCourses =
        (_externalCoursesResponse['data'] as List<Map<String, dynamic>>)
            .map((item) => ExternalCourseDTO.fromJson(item))
            .toList();

    return Future.value(_externalCourses);
  }

  @override
  Future<List<CourseDTO>> getMyCourses() {
    final _courses = _myCourses
        .map((item) => CourseDTO.fromJson(item))
        .toList();

    return Future.value(_courses);
  }

  @override
  Future<CourseItemDTO> courseItemGetDetails(String courseId) async {
    final courseItemDTO = _findCourseById(
      needle: courseId,
      haystack: _myCourses,
    );

    if (courseItemDTO != null) {
      return courseItemDTO;
    }

    throw DioException(
      requestOptions: RequestOptions(path: ""),
      error: "Curso não encontrado",
    );
  }

  CourseItemDTO? _findCourseById({
    required String needle,
    required List<Map<String, dynamic>> haystack,
  }) {
    for (var course in haystack) {
      if (course['id'] == needle) {
        return CourseItemDTO.fromJson(course);
      }

      if (course.containsKey('childrens') && course['childrens'] is Map) {
        final childrens = course['childrens']['items'] as List<dynamic>;
        final result = _findCourseById(
          needle: needle,
          haystack: childrens.cast<Map<String, dynamic>>(),
        );
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  String get fakeMongoId {
    const chars = 'abcdef0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(24, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  String get _fakePassword => "765432e1";

  UserDTO get _mockUser => UserDTO(
    id: fakeMongoId,
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

  late final List<Map<String, dynamic>> _myCourses = [
    {
      "id": fakeMongoId,
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {"id": fakeMongoId, "name": "MBA", "slug": "mba"},
      "description":
          "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/30/200/300"},
      },
      "categories": [
        {
          "id": fakeMongoId,
          "name": "Ciências da Mente",
          "slug": "ciencias_da_mente",
        },
        {"id": fakeMongoId, "name": "Liderança", "slug": "lideranca"},
        {"id": fakeMongoId, "name": "Negócios", "slug": "negocios"},
      ],
      "teachers": [
        {
          "id": fakeMongoId,
          "name": "Roberto Shinyashiki",
          "avatar_url": "https://picsum.photos/id/40/200/300",
          "highlight": true,
        },
      ],
      "childrens": {
        "meta": {"label": "Disciplinas", "total": 10},
        "items": [
          {
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "label": "Aula",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url":
                          "https://b-vz-df032af7-1d1.tv.pandavideo.com.br/1cea11b0-fa15-4c9b-ac2d-099fac53d54a/playlist.m3u8",
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
                  "thumb": {
                    "type": "image",
                    "data": {"url": "https://picsum.photos/id/30/200/300"},
                  },
                  "content": {
                    "video": {
                      "url":
                          "https://b-vz-df032af7-1d1.tv.pandavideo.com.br/1cea11b0-fa15-4c9b-ac2d-099fac53d54a/playlist.m3u8",
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
                      "title": "Manual do Aluno",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    {
                      "url": "https://example.com/file.pdf",
                      "title": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    {
                      "url": "https://example.com/file.pdf",
                      "title": "Manual do Aluno",
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
      "id": fakeMongoId,
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {"id": fakeMongoId, "name": "MBA", "slug": "mba"},
      "description":
          "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/30/200/300"},
      },
      "categories": [
        {
          "id": fakeMongoId,
          "name": "Ciências da Mente",
          "slug": "ciencias_da_mente",
        },
        {"id": fakeMongoId, "name": "Liderança", "slug": "lideranca"},
        {"id": fakeMongoId, "name": "Negócios", "slug": "negocios"},
      ],
      "teachers": [
        {
          "id": fakeMongoId,
          "name": "Roberto Shinyashiki",
          "avatar_url": "https://picsum.photos/id/40/200/300",
          "highlight": true,
        },
      ],
      "childrens": {
        "meta": {"label": "Disciplinas", "total": 10},
        "items": [
          {
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "label": "Aula",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    {
                      "url": "https://example.com/file.pdf",
                      "title": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    {
                      "url": "https://example.com/file.pdf",
                      "title": "Manual do Aluno",
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
      "id": fakeMongoId,
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {"id": fakeMongoId, "name": "MBA", "slug": "mba"},
      "description":
          "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/30/200/300"},
      },
      "categories": [
        {
          "id": fakeMongoId,
          "name": "Ciências da Mente",
          "slug": "ciencias_da_mente",
        },
        {"id": fakeMongoId, "name": "Liderança", "slug": "lideranca"},
        {"id": fakeMongoId, "name": "Negócios", "slug": "negocios"},
      ],
      "teachers": [
        {
          "id": fakeMongoId,
          "name": "Roberto Shinyashiki",
          "avatar_url": "https://picsum.photos/id/40/200/300",
          "highlight": true,
        },
      ],
      "childrens": {
        "meta": {"label": "Disciplinas", "total": 10},
        "items": [
          {
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "label": "Aula",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    {
                      "url": "https://example.com/file.pdf",
                      "title": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    {
                      "url": "https://example.com/file.pdf",
                      "title": "Manual do Aluno",
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
      "id": fakeMongoId,
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {"id": fakeMongoId, "name": "MBA", "slug": "mba"},
      "description":
          "Curso de MBA em Ciências da Mente e Liderança Humanizada.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/30/200/300"},
      },
      "categories": [
        {
          "id": fakeMongoId,
          "name": "Ciências da Mente",
          "slug": "ciencias_da_mente",
        },
        {"id": fakeMongoId, "name": "Liderança", "slug": "lideranca"},
        {"id": fakeMongoId, "name": "Negócios", "slug": "negocios"},
      ],
      "teachers": [
        {
          "id": fakeMongoId,
          "name": "Roberto Shinyashiki",
          "avatar_url": "https://picsum.photos/id/40/200/300",
          "highlight": true,
        },
      ],
      "childrens": {
        "meta": {"label": "Disciplinas", "total": 10},
        "items": [
          {
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "label": "Aula",
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
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
            "id": fakeMongoId,
            "title": "Introdução à Liderança Humanizada",
            "description": "Aprenda os fundamentos da liderança humanizada.",
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Roberto Shinyashiki",
                "avatar_url": "https://picsum.photos/id/40/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/30/200/300"},
            },
            "childrens": {
              "meta": {"label": "Aulas", "total": 10},
              "items": [
                {
                  "id": fakeMongoId,
                  "title": "O que é Liderança Humanizada?",
                  "description": "Entenda o conceito de liderança humanizada.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                  ],
                },
                {
                  "id": fakeMongoId,
                  "title": "Princípios da Liderança Humanizada",
                  "description": "Explore os princípios fundamentais.",
                  "teachers": [
                    {
                      "id": fakeMongoId,
                      "name": "Roberto Shinyashiki",
                      "avatar_url": "https://picsum.photos/id/40/200/300",
                      "highlight": true,
                    },
                  ],
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
                      "title": "Manual do Aluno",
                      "description": "Aqui você encontra tudo que precisa",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    {
                      "url": "https://example.com/file.pdf",
                      "title": "Manual do Aluno",
                      "thumb": {
                        "type": "image",
                        "data": {"url": "https://picsum.photos/id/30/200/300"},
                      },
                    },
                    {
                      "url": "https://example.com/file.pdf",
                      "title": "Manual do Aluno",
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
  Map<String, dynamic> get _externalCoursesResponse => {
    "total": 2,
    "data": [
      {
        "id": fakeMongoId,
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
}

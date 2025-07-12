import 'dart:math';

import 'package:dio/dio.dart';
import 'package:unifast_portal/domain/auth/errors/belluga_auth_errors.dart';
import 'package:unifast_portal/domain/repositories/auth_repository_contract.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/category_dto.dart';
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
  Future<List<CourseDTO>> getUnifastTracks() {
    final _courses = _unifastTracks
        .map((item) => CourseDTO.fromJson(item))
        .toList();

    return Future.value(_courses);
  }

  @override
  Future<List<CourseDTO>> getLastFastTrackCourses() {
    _unifastTracks.sublist(0, 3);
    final _courses = _unifastTracks
        .map((item) => CourseDTO.fromJson(item))
        .toList();

    return Future.value(_courses);
  }

  @override
  Future<CourseItemDTO> courseItemGetDetails(String courseId) async {
    final _allCourses = _myCourses;
    _allCourses.addAll(_unifastTracks);
    final courseItemDTO = _findCourseById(
      needle: courseId,
      haystack: _allCourses,
    );

    if (courseItemDTO != null) {
      return courseItemDTO;
    }

    throw DioException(
      requestOptions: RequestOptions(path: ""),
      error: "Curso não encontrado",
    );
  }

  @override
  Future<List<CategoryDTO>> getFastTracksCategories() {
    final _courses = _fastTracksCategories
        .map((item) => CategoryDTO.fromJson(item))
        .toList();

    return Future.value(_courses);
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

  final List<Map<String, dynamic>> _fastTracksCategories = [
    {
      "id": "668ed5a2c589a1b2c3d4e5f3",
      "name": "Soft Skills",
      "slug": "soft-skills",
      "color_hex": "007FF9",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f4",
      "name": "Liderança",
      "slug": "lideranca",
      "color_hex": "#FF0000",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f4",
      "name": "Inteligência Emocional",
      "slug": "inteligencia-emocional",
      "color_hex": "#FF0000",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f4",
      "name": "Experiência do Cliente",
      "slug": "experiencia-do-cliente",
      "color_hex": "#FF0000",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f4",
      "name": "Inteligência Artificial",
      "slug": "inteligencia-artificial",
      "color_hex": "#FF0000",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f4",
      "name": "Gestão Financeira",
      "slug": "gestao-financeira",
      "color_hex": "#FF0000",
    },
  ];

  late final List<Map<String, dynamic>> _unifastTracks = [
    {
      "id": "668ed5a2c589a1b2c3d4e5f1",
      "title": "Masterclass em Liderança Exponencial",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e5f2",
        "name": "Masterclass",
        "slug": "masterclass",
      },
      "description":
          "Aprenda a liderar na nova economia com estratégias de alto impacto e crescimento acelerado.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/101/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Liderança",
          "slug": "lideranca",
          "color_hex": "007FF9",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Inovação",
          "slug": "inovacao",
          "color_hex": "#FF0000",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Sofia Almeida",
          "avatar_url": "https://picsum.photos/id/102/200/300",
          "highlight": true,
        },
      ],
      "files": [
        {
          "url": "https://www.orimi.com/pdf-test.pdf",
          "title": "Plano de Aulas Completo",
          "description": "Cronograma detalhado da masterclass.",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/103/200/300"},
          },
        },
      ],
      "childrens": {
        "meta": {"label": "Aulas", "total": 4},
        "items": [
          {
            "id": "668ed5a2c589a1b2c3d4e5f6",
            "title": "Módulo 1: Mindset do Líder Exponencial",
            "description": "Construindo a mentalidade para o crescimento.",
            "teachers": [
              {
                "id": "668ed5a2c589a1b2c3d4e5f5",
                "name": "Sofia Almeida",
                "avatar_url": "https://picsum.photos/id/102/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/104/200/300"},
            },
            "files": [],
          },
          {
            "id": "668ed5a2c589a1b2c3d4e5f7",
            "title": "Módulo 2: Ferramentas de Gestão Ágil",
            "description": "Aplicando Scrum e Kanban na sua equipe.",
            "teachers": [
              {
                "id": "668ed5a2c589a1b2c3d4e5f5",
                "name": "Sofia Almeida",
                "avatar_url": "https://picsum.photos/id/102/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/100/200/300"},
            },
            "files": [
              {
                "url": "https://www.orimi.com/pdf-test.pdf",
                "title": "Templates de Kanban",
                "description": "Modelos prontos para usar.",
                "thumb": {
                  "type": "image",
                  "data": {"url": "https://picsum.photos/id/106/200/300"},
                },
              },
            ],
          },
        ],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f8",
      "title": "Bootcamp de Finanças para Empreendedores",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e5f9",
        "name": "Bootcamp",
        "slug": "bootcamp",
      },
      "description":
          "Domine o fluxo de caixa, investimentos e a saúde financeira do seu negócio.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/201/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e5fa",
          "name": "Finanças",
          "slug": "financas",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5fb",
          "name": "Negócios",
          "slug": "negocios",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5fc",
          "name": "Lucas Pereira",
          "avatar_url": "https://picsum.photos/id/202/200/300",
          "highlight": true,
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5fd",
          "name": "Ana Costa",
          "avatar_url": "https://picsum.photos/id/203/200/300",
          "highlight": false,
        },
      ],
      "files": [
        {
          "url": "https://www.orimi.com/pdf-test.pdf",
          "title": "Planilha de Fluxo de Caixa",
          "description": "Modelo exclusivo para alunos.",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/204/200/300"},
          },
        },
        {
          "url": "https://www.orimi.com/pdf-test.pdf",
          "title": "Guia de Investimentos Anjo",
          "description": "Como captar recursos para sua startup.",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/200/200/300"},
          },
        },
      ],
      "childrens": {
        "meta": {"label": "Aulas", "total": 8},
        "items": [
          {
            "id": "668ed5a2c589a1b2c3d4e5fe",
            "title": "Aula 1: Análise de Demonstrativos Financeiros",
            "description": "Entenda o balanço e o DRE da sua empresa.",
            "teachers": [
              {
                "id": "668ed5a2c589a1b2c3d4e5fc",
                "name": "Lucas Pereira",
                "avatar_url": "https://picsum.photos/id/202/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/206/200/300"},
            },
            "files": [],
          },
          {
            "id": "668ed5a2c589a1b2c3d4e5ff",
            "title": "Aula 2: Precificação Estratégica",
            "description": "Como definir o preço certo para seus produtos.",
            "teachers": [
              {
                "id": "668ed5a2c589a1b2c3d4e5fd",
                "name": "Ana Costa",
                "avatar_url": "https://picsum.photos/id/198/200/300",
                "highlight": false,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/206/200/300"},
            },
            "files": [],
          },
        ],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e600",
      "title": "Curso de Comunicação e Oratória para Líderes",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e601",
        "name": "Curso",
        "slug": "curso",
      },
      "description":
          "Aprenda a comunicar suas ideias com clareza e a inspirar suas equipes através da fala.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/301/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e602",
          "name": "Comunicação",
          "slug": "comunicacao",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Liderança",
          "slug": "lideranca",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e603",
          "name": "Autoconhecimento",
          "slug": "autoconhecimento",
        },
        {"id": "668ed5a2c589a1b2c3d4e603", "name": "Outra", "slug": "other"},
        {
          "id": "668ed5a2c589a1b2c3d4e603",
          "name": "Mais uma",
          "slug": "mais-uma",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e603",
          "name": "Eramos Seis",
          "slug": "eramos-seis",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e604",
          "name": "Isabela Ferreira",
          "avatar_url": "https://picsum.photos/id/302/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Aulas", "total": 12},
        "items": [
          {
            "id": "668ed5a2c589a1b2c3d4e605",
            "title": "Técnicas de Storytelling",
            "description":
                "Conecte-se com sua audiência através de narrativas.",
            "teachers": [
              {
                "id": "668ed5a2c589a1b2c3d4e604",
                "name": "Isabela Ferreira",
                "avatar_url": "https://picsum.photos/id/302/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/321/200/300"},
            },
            "files": [],
          },
        ],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e606",
      "title": "Imersão em Marketing Digital de Performance",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e607",
        "name": "Imersão",
        "slug": "imersao",
      },
      "description":
          "Foco total em estratégias de tráfego pago, SEO e análise de métricas para resultados reais.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/401/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e608",
          "name": "Marketing",
          "slug": "marketing",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5fb",
          "name": "Negócios",
          "slug": "negocios",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e609",
          "name": "Gustavo Oliveira",
          "avatar_url": "https://picsum.photos/id/402/200/300",
          "highlight": true,
        },
      ],
      "files": [
        {
          "url": "https://www.orimi.com/pdf-test.pdf",
          "title": "Checklist de SEO On-Page",
          "description": "Otimize suas páginas para os buscadores.",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/403/200/300"},
          },
        },
      ],
      "childrens": {
        "meta": {"label": "Módulos", "total": 6},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e610",
      "title": "Workshop de Gestão de Conflitos",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e611",
        "name": "Workshop",
        "slug": "workshop",
      },
      "description":
          "Desenvolva habilidades práticas para mediar e resolver conflitos em equipes de alta performance.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/501/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Liderança",
          "slug": "lideranca",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e602",
          "name": "Comunicação",
          "slug": "comunicacao",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e604",
          "name": "Isabela Ferreira",
          "avatar_url": "https://picsum.photos/id/302/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Sessões", "total": 3},
        "items": [
          {
            "id": "668ed5a2c589a1b2c3d4e612",
            "title": "Sessão Prática: Role-playing",
            "description": "Simulações de situações reais de conflito.",
            "teachers": [
              {
                "id": "668ed5a2c589a1b2c3d4e604",
                "name": "Isabela Ferreira",
                "avatar_url": "https://picsum.photos/id/302/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/502/200/300"},
            },
            "files": [],
          },
        ],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e613",
      "title": "MBA em Gestão de Projetos e Inovação",
      "type": {"id": "668ed5a2c589a1b2c3d4e5f2", "name": "MBA", "slug": "mba"},
      "description":
          "Formação completa para gerentes de projeto que desejam liderar a transformação digital.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/5/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Inovação",
          "slug": "inovacao",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5fb",
          "name": "Negócios",
          "slug": "negocios",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e614",
          "name": "Produtividade",
          "slug": "produtividade",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Sofia Almeida",
          "avatar_url": "https://picsum.photos/id/102/200/300",
          "highlight": true,
        },
        {
          "id": "668ed5a2c589a1b2c3d4e609",
          "name": "Gustavo Oliveira",
          "avatar_url": "https://picsum.photos/id/402/200/300",
          "highlight": false,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Disciplinas", "total": 15},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e615",
      "title": "Curso de Inteligência Emocional no Trabalho",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e601",
        "name": "Curso",
        "slug": "curso",
      },
      "description":
          "Gerencie suas emoções, melhore relacionamentos e aumente sua performance profissional.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/701/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e603",
          "name": "Autoconhecimento",
          "slug": "autoconhecimento",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Liderança",
          "slug": "lideranca",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5fd",
          "name": "Ana Costa",
          "avatar_url": "https://picsum.photos/id/203/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Aulas", "total": 10},
        "items": [
          {
            "id": "668ed5a2c589a1b2c3d4e616",
            "title": "Os 5 Pilares da Inteligência Emocional",
            "description":
                "Fundamentos de Daniel Goleman aplicados ao dia a dia.",
            "teachers": [
              {
                "id": "668ed5a2c589a1b2c3d4e5fd",
                "name": "Ana Costa",
                "avatar_url": "https://picsum.photos/id/203/200/300",
                "highlight": true,
              },
            ],
            "thumb": {
              "type": "image",
              "data": {"url": "https://picsum.photos/id/702/200/300"},
            },
            "files": [],
          },
        ],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e617",
      "title": "Masterclass: Negociação e Persuasão",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e5f2",
        "name": "Masterclass",
        "slug": "masterclass",
      },
      "description":
          "Técnicas avançadas de negociação para fechar grandes contratos e influenciar positivamente.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/254/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e602",
          "name": "Comunicação",
          "slug": "comunicacao",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5fb",
          "name": "Negócios",
          "slug": "negocios",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5fc",
          "name": "Lucas Pereira",
          "avatar_url": "https://picsum.photos/id/202/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Tópicos", "total": 5},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e618",
      "title": "Bootcamp de Growth Hacking",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e5f9",
        "name": "Bootcamp",
        "slug": "bootcamp",
      },
      "description":
          "Estratégias de crescimento rápido com baixo custo para startups e produtos digitais.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/901/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e608",
          "name": "Marketing",
          "slug": "marketing",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Inovação",
          "slug": "inovacao",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e609",
          "name": "Gustavo Oliveira",
          "avatar_url": "https://picsum.photos/id/402/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Sprints", "total": 4},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e619",
      "title": "Curso de Gestão do Tempo e Produtividade",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e601",
        "name": "Curso",
        "slug": "curso",
      },
      "description":
          "Métodos como GTD, Pomodoro e Matriz de Eisenhower para organizar sua vida e fazer mais.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/111/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e614",
          "name": "Produtividade",
          "slug": "produtividade",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e603",
          "name": "Autoconhecimento",
          "slug": "autoconhecimento",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5fd",
          "name": "Ana Costa",
          "avatar_url": "https://picsum.photos/id/203/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Aulas", "total": 9},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e620",
      "title": "Imersão em Design Thinking",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e607",
        "name": "Imersão",
        "slug": "imersao",
      },
      "description":
          "Aprenda a resolver problemas complexos com uma abordagem centrada no ser humano.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/121/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Inovação",
          "slug": "inovacao",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5fb",
          "name": "Negócios",
          "slug": "negocios",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Sofia Almeida",
          "avatar_url": "https://picsum.photos/id/102/200/300",
          "highlight": true,
        },
      ],
      "files": [
        {
          "url": "https://www.orimi.com/pdf-test.pdf",
          "title": "Canvas de Design Thinking",
          "description": "Ferramenta visual para seus projetos.",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/122/200/300"},
          },
        },
      ],
      "childrens": {
        "meta": {"label": "Etapas", "total": 5},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e621",
      "title": "Workshop de Feedback Construtivo",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e611",
        "name": "Workshop",
        "slug": "workshop",
      },
      "description":
          "Como dar e receber feedbacks que realmente desenvolvem pessoas e equipes.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/131/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Liderança",
          "slug": "lideranca",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e602",
          "name": "Comunicação",
          "slug": "comunicacao",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e604",
          "name": "Isabela Ferreira",
          "avatar_url": "https://picsum.photos/id/302/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Atividades", "total": 2},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e622",
      "title": "MBA Executivo em Negócios Digitais",
      "type": {"id": "668ed5a2c589a1b2c3d4e5f2", "name": "MBA", "slug": "mba"},
      "description":
          "Prepare-se para liderar empresas na era digital, dominando e-commerce, dados e novos modelos de negócio.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/141/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e5fb",
          "name": "Negócios",
          "slug": "negocios",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e608",
          "name": "Marketing",
          "slug": "marketing",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Inovação",
          "slug": "inovacao",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5fc",
          "name": "Lucas Pereira",
          "avatar_url": "https://picsum.photos/id/202/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Módulos", "total": 18},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e623",
      "title": "Curso de Copywriting para Vendas",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e601",
        "name": "Curso",
        "slug": "curso",
      },
      "description":
          "Escreva textos persuasivos que convertem visitantes em clientes.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/151/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e608",
          "name": "Marketing",
          "slug": "marketing",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e602",
          "name": "Comunicação",
          "slug": "comunicacao",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e609",
          "name": "Gustavo Oliveira",
          "avatar_url": "https://picsum.photos/id/402/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Aulas", "total": 7},
        "items": [],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e624",
      "title": "Imersão Liderança Servidora",
      "type": {
        "id": "668ed5a2c589a1b2c3d4e607",
        "name": "Imersão",
        "slug": "imersao",
      },
      "description":
          "Uma abordagem de liderança focada em servir, desenvolver e empoderar a equipe.",
      "thumb": {
        "type": "image",
        "data": {"url": "https://picsum.photos/id/161/200/300"},
      },
      "categories": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Liderança",
          "slug": "lideranca",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e603",
          "name": "Autoconhecimento",
          "slug": "autoconhecimento",
        },
      ],
      "teachers": [
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Sofia Almeida",
          "avatar_url": "https://picsum.photos/id/102/200/300",
          "highlight": true,
        },
      ],
      "files": [],
      "childrens": {
        "meta": {"label": "Encontros", "total": 3},
        "items": [],
      },
    },
  ];

  late final List<Map<String, dynamic>> _myCourses = [
    {
      "id": "9e2b36b89315617e5b6d891f",
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
      "files": [
        {
          "url": "https://www.orimi.com/pdf-test.pdf",
          "title": "Manual do Aluno",
          "description": "Aqui você encontra tudo que precisa",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/30/200/300"},
          },
        },
        {
          "url": "https://www.orimi.com/pdf-test.pdf",
          "title": "Manual do Aluno",
          "description": "Aqui você encontra tudo que precisa",
          "thumb": {
            "type": "image",
            "data": {"url": "https://picsum.photos/id/30/200/300"},
          },
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
            "files": [
              {
                "url": "https://www.orimi.com/pdf-test.pdf",
                "title": "Manual do Aluno",
                "description": "Aqui você encontra tudo que precisa",
                "thumb": {
                  "type": "image",
                  "data": {"url": "https://picsum.photos/id/30/200/300"},
                },
              },
              {
                "url": "https://www.orimi.com/pdf-test.pdf",
                "title": "Manual do Aluno",
                "description": "Aqui você encontra tudo que precisa",
                "thumb": {
                  "type": "image",
                  "data": {"url": "https://picsum.photos/id/30/200/300"},
                },
              },
            ],
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
                      "url": "https://www.orimi.com/pdf-test.pdf",
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
                      "url": "https://www.orimi.com/pdf-test.pdf",
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
                      "url": "https://www.orimi.com/pdf-test.pdf",
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

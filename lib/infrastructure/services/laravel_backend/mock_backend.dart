import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:unifast_portal/application/extensions/color_to_hex.dart';
import 'package:unifast_portal/domain/auth/errors/belluga_auth_errors.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_summary_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/external_course_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/notes/note_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/user_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/user_profile_dto.dart';
import 'package:unifast_portal/infrastructure/services/laravel_backend/backend_contract.dart';

class MockBackend extends BackendContract {
  final dio = Dio();

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
  Future<List<CourseItemSummaryDTO>> getMyCourses() {
    final _courses = _myCourses
        .map((item) => CourseItemSummaryDTO.fromJson(item))
        .toList();

    return Future.value(_courses);
  }

  @override
  Future<List<CourseItemSummaryDTO>> getUnifastTracks() {
    final _courses = _unifastTracks
        .map((item) => CourseItemSummaryDTO.fromJson(item))
        .toList();

    return Future.value(_courses);
  }

  @override
  Future<List<CourseItemSummaryDTO>> getLastFastTrackCourses() {
    _unifastTracks.sublist(0, 3);
    final _courses = _unifastTracks
        .map((item) => CourseItemSummaryDTO.fromJson(item))
        .toList();

    return Future.value(_courses);
  }

  @override
  Future<CourseItemDetailsDTO> courseItemGetDetails(String courseId) async {
    await Future.delayed(Duration(seconds: 1));

    final _allCourses = _myCourses;
    _allCourses.addAll(_unifastTracks);
    final courseItemDTO = _findCourseById(
      needle: courseId,
      haystack: _courseItemListDetails,
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

  CourseItemDetailsDTO? _findCourseById({
    required String needle,
    required List<Map<String, dynamic>> haystack,
  }) {
    final Map<String, dynamic> _courseItemDetailsRaw = haystack.firstWhere(
      (item) => item['id'] == needle,
    );

    return CourseItemDetailsDTO.fromJson(_courseItemDetailsRaw);
  }

  @override
  Future<List<NoteDTO>> getNotes(String courseItemId) {
    // Simulate fetching notes for a course item
    return Future.delayed(Duration(seconds: 1), () {
      if (!_notes.containsKey(courseItemId)) {
        return [];
      }
      return _notes[courseItemId]!;
    });
  }

  @override
  Future<void> createNote({
    required String courseItemId,
    required String content,
    Duration? position,
    required Color color,
  }) {
    // Simulate saving a note
    return Future.delayed(Duration(seconds: 1), () {
      final NoteDTO _note = NoteDTO(
        id: fakeMongoId,
        courseItemId: courseItemId,
        content: content,
        colorHex: color.toHex(),
        position: position?.toString(),
      );
      _notes.putIfAbsent(courseItemId, () => []).add(_note);
    });
  }

  @override
  Future<void> updateNote({
    required String id,
    required String courseItemId,
    required String content,
    Duration? position,
    required Color color,
  }) {
    return Future.delayed(Duration(seconds: 1), () {
      if (!_notes.containsKey(courseItemId)) {
        throw Exception("Note not found for course item: $courseItemId");
      }
      final notesList = _notes[courseItemId]!;
      final index = notesList.indexWhere((n) => n.id == id);
      if (index == -1) {
        throw Exception("Note not found with id: $id");
      }
      notesList[index].colorHex = color.toHex();
      notesList[index].content = content;
      notesList[index].position = position?.toString();
    });
  }

  @override
  Future<void> deleteNote(String id) {
    return Future.delayed(Duration(seconds: 1), () {
      _notes.forEach((courseItemId, notesList) {
        final index = notesList.indexWhere((n) => n.id == id);
        if (index != -1) {
          notesList.removeAt(index);
        }
      });
      print("Note DELETED successfully (MOCK).");
    });
  }

  final Map<String, List<NoteDTO>> _notes = {};

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
      "color_hex": "4A90E2",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f4",
      "name": "Liderança",
      "slug": "lideranca",
      "color_hex": "#50E3C2",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f5",
      "name": "Inteligência Emocional",
      "slug": "inteligencia-emocional",
      "color_hex": "#F5A623",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f6",
      "name": "Experiência do Cliente",
      "slug": "experiencia-do-cliente",
      "color_hex": "#D0021B",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f7",
      "name": "Inteligência Artificial",
      "slug": "inteligencia-artificial",
      "color_hex": "#9013FE",
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f8",
      "name": "Gestão Financeira",
      "slug": "gestao-financeira",
      "color_hex": "#4A4A4A",
    },
  ];

  List<Map<String, dynamic>> get _courseItemListDetails => [
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
          "name": "Soft Skills",
          "slug": "soft-skills",
          "color_hex": "4A90E2",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Liderança",
          "slug": "lideranca",
          "color_hex": "#50E3C2",
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
            "id": "668ed6a2c589a1b2c3d4e5f9",
            "title": "Mindset do Líder Exponencial",
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
          },
          {
            "id": "668ed5a2c589a1b2c3d4e5f7",
            "title": "Ferramentas de Gestão Ágil",
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
          },
          {
            "id": "668ed5a2c589a1b2c3d4e5f8",
            "title": "Aplicando a Gestão Ágil em seu negócio",
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
          },
        ],
      },
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f6",
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {"id": fakeMongoId, "name": "MBA", "slug": "mba"},
      "description":
          "MBA Ciência da Mente e Liderança Humanizada: Curso EAD que tem por objetivo líderes mais eficazes. O MBA é reconhecido pelo MEC, tem como carga horária 360 horas sendo elas subdivididas em 18 módulos.  Destinado a Líderes de equipe, Coordenadores, Gestores e Diretores, C-Levels, Empreendedores, Palestrantes, Coaches e Terapeutas.",
      "thumb": {
        "type": "image",
        "data": {
          "url":
              "https://agazetadoacre.com/wp-content/uploads/2021/10/rshinyashiki_20201117_p_2444667468612763367_1_2444667468612763367.jpg",
        },
      },
      "categories": [
        {
          "id": fakeMongoId,
          "name": "Ciências da Mente",
          "slug": "ciencias_da_mente",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Liderança",
          "slug": "lideranca",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Soft Skills",
          "slug": "soft-skills",
        },
      ],
      "teachers": [
        {
          "id": fakeMongoId,
          "name": "Roberto Shinyashiki",
          "avatar_url":
              "https://classic.exame.com/wp-content/uploads/2016/10/size_960_16_9_roberto-shinyashiki.jpg",
          "highlight": true,
        },
      ],
      "childrens": {
        "meta": {"label": "Aulas", "total": 2},
        "items": [
          {
            "id": "668ed5a2c589a1b2c3d4e5f8",
            "title": "Disciplina Teste 1",
            "description":
                "MBA Ciência da Mente e Liderança Humanizada: Curso EAD que tem por objetivo líderes mais eficazes. O MBA é reconhecido pelo MEC, tem como carga horária 360 horas sendo elas subdivididas em 18 módulos.  Destinado a Líderes de equipe, Coordenadores, Gestores e Diretores, C-Levels, Empreendedores, Palestrantes, Coaches e Terapeutas.",
            "thumb": {
              "type": "image",
              "data": {
                "url":
                    "https://agazetadoacre.com/wp-content/uploads/2021/10/rshinyashiki_20201117_p_2444667468612763367_1_2444667468612763367.jpg",
              },
            },
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Francelino Neto",
                "avatar_url":
                    "https://classic.exame.com/wp-content/uploads/2016/10/size_960_16_9_roberto-shinyashiki.jpg",
              },
            ],
          },
          {
            "id": "668ed5a2c589a1b2c3d4e5f9",
            "title": "Disciplina Teste 2",
            "description":
                "MBA Ciência da Mente e Liderança Humanizada: Curso EAD que tem por objetivo líderes mais eficazes. O MBA é reconhecido pelo MEC, tem como carga horária 360 horas sendo elas subdivididas em 18 módulos.  Destinado a Líderes de equipe, Coordenadores, Gestores e Diretores, C-Levels, Empreendedores, Palestrantes, Coaches e Terapeutas.",
            "thumb": {
              "type": "image",
              "data": {
                "url":
                    "https://agazetadoacre.com/wp-content/uploads/2021/10/rshinyashiki_20201117_p_2444667468612763367_1_2444667468612763367.jpg",
              },
            },
            "teachers": [
              {
                "id": fakeMongoId,
                "name": "Fulano de Tal",
                "avatar_url":
                    "https://classic.exame.com/wp-content/uploads/2016/10/size_960_16_9_roberto-shinyashiki.jpg",
                "highlight": false,
              },
            ],
          },
        ],
      },
    },
    {
      "id": "668ed6a2c589a1b2c3d4e5f9",
      "title": "Mindset do Líder Exponencial",
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
      "parent": {
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
      },
      "next": {
        "id": "668ed5a2c589a1b2c3d4e5f7",
        "title": "Ferramentas de Gestão Ágil",
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
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f7",
      "title": "Ferramentas de Gestão Ágil",
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
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f8",
      "title": "Aplicando a Gestão Ágil em seu negócio",
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
          "name": "Soft Skills",
          "slug": "soft-skills",
          "color_hex": "4A90E2",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Liderança",
          "slug": "lideranca",
          "color_hex": "#50E3C2",
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
            "id": "668ed6a2c589a1b2c3d4e5f9",
            "title": "Mindset do Líder Exponencial",
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
          },
          {
            "id": "668ed5a2c589a1b2c3d4e5f7",
            "title": "Ferramentas de Gestão Ágil",
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
          },
          {
            "id": "668ed5a2c589a1b2c3d4e5f8",
            "title": "Aplicando a Gestão Ágil em seu negócio",
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
          "id": "668ed5a2c589a1b2c3d4e5f8",
          "name": "Gestão Financeira",
          "slug": "gestao-financeira",
          "color_hex": "#4A4A4A",
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
          "id": "668ed5a2c589a1b2c3d4e5f7",
          "name": "Inteligência Artificial",
          "slug": "inteligencia-artificial",
          "color_hex": "#9013FE",
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
          "id": "668ed5a2c589a1b2c3d4e5f6",
          "name": "Experiência do Cliente",
          "slug": "experiencia-do-cliente",
          "color_hex": "#D0021B",
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
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Inteligência Emocional",
          "slug": "inteligencia-emocional",
          "color_hex": "#F5A623",
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
          "name": "Liderança",
          "slug": "lideranca",
          "color_hex": "#50E3C2",
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
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Soft Skills",
          "slug": "soft-skills",
          "color_hex": "4A90E2",
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
          "id": "668ed5a2c589a1b2c3d4e5f7",
          "name": "Inteligência Artificial",
          "slug": "inteligencia-artificial",
          "color_hex": "#9013FE",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f8",
          "name": "Gestão Financeira",
          "slug": "gestao-financeira",
          "color_hex": "#4A4A4A",
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
          "id": "668ed5a2c589a1b2c3d4e5f6",
          "name": "Experiência do Cliente",
          "slug": "experiencia-do-cliente",
          "color_hex": "#D0021B",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f7",
          "name": "Inteligência Artificial",
          "slug": "inteligencia-artificial",
          "color_hex": "#9013FE",
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
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Inteligência Emocional",
          "slug": "inteligencia-emocional",
          "color_hex": "#F5A623",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f6",
          "name": "Experiência do Cliente",
          "slug": "experiencia-do-cliente",
          "color_hex": "#D0021B",
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
          "name": "Liderança",
          "slug": "lideranca",
          "color_hex": "#50E3C2",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Inteligência Emocional",
          "slug": "inteligencia-emocional",
          "color_hex": "#F5A623",
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
          "name": "Soft Skills",
          "slug": "soft-skills",
          "color_hex": "4A90E2",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Liderança",
          "slug": "lideranca",
          "color_hex": "#50E3C2",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Inteligência Emocional",
          "slug": "inteligencia-emocional",
          "color_hex": "#F5A623",
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
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Liderança",
          "slug": "lideranca",
          "color_hex": "#50E3C2",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Inteligência Emocional",
          "slug": "inteligencia-emocional",
          "color_hex": "#F5A623",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f6",
          "name": "Experiência do Cliente",
          "slug": "experiencia-do-cliente",
          "color_hex": "#D0021B",
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
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Inteligência Emocional",
          "slug": "inteligencia-emocional",
          "color_hex": "#F5A623",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f6",
          "name": "Experiência do Cliente",
          "slug": "experiencia-do-cliente",
          "color_hex": "#D0021B",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f7",
          "name": "Inteligência Artificial",
          "slug": "inteligencia-artificial",
          "color_hex": "#9013FE",
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
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Liderança",
          "slug": "lideranca",
          "color_hex": "#50E3C2",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Inteligência Emocional",
          "slug": "inteligencia-emocional",
          "color_hex": "#F5A623",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f6",
          "name": "Experiência do Cliente",
          "slug": "experiencia-do-cliente",
          "color_hex": "#D0021B",
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
      "id": "668ed5a2c589a1b2c3d4e5f6",
      "title": "MBA em Ciências da Mente e Liderança Humanizada",
      "type": {"id": fakeMongoId, "name": "MBA", "slug": "mba"},
      "description":
          "MBA Ciência da Mente e Liderança Humanizada: Curso EAD que tem por objetivo líderes mais eficazes. O MBA é reconhecido pelo MEC, tem como carga horária 360 horas sendo elas subdivididas em 18 módulos.  Destinado a Líderes de equipe, Coordenadores, Gestores e Diretores, C-Levels, Empreendedores, Palestrantes, Coaches e Terapeutas.",
      "thumb": {
        "type": "image",
        "data": {
          "url":
              "https://agazetadoacre.com/wp-content/uploads/2021/10/rshinyashiki_20201117_p_2444667468612763367_1_2444667468612763367.jpg",
        },
      },
      "categories": [
        {
          "id": fakeMongoId,
          "name": "Ciências da Mente",
          "slug": "ciencias_da_mente",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f4",
          "name": "Liderança",
          "slug": "lideranca",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f3",
          "name": "Soft Skills",
          "slug": "soft-skills",
        },
      ],
      "teachers": [
        {
          "id": fakeMongoId,
          "name": "Roberto Shinyashiki",
          "avatar_url":
              "https://classic.exame.com/wp-content/uploads/2016/10/size_960_16_9_roberto-shinyashiki.jpg",
          "highlight": true,
        },
      ],
    },
    {
      "id": "668ed5a2c589a1b2c3d4e5f7",
      "title":
          "Pós-Graduação em Terapia Integrativa: Desenvolvimento Humano como Modelo de Negócios",
      "type": {
        "id": fakeMongoId,
        "name": "Pós-Graduação",
        "slug": "pos_graduacao",
      },
      "description":
          "Domine as metodologias terapêuticas exclusivas de Tadashi Kadomoto. Transforme-se em um profissional da saúde completo, capacitado a promover o bem estar e a qualidade de vida, atuando nas 3 grandes áreas de uma vida equilibrada: corpo, mente e espírito.",
      "thumb": {
        "type": "image",
        "data": {
          "url":
              "https://pam1.com.br/wp-content/uploads/2024/06/IMG-20240621-WA0087.jpg",
        },
      },
      "categories": [
        {
          "id": fakeMongoId,
          "name": "Terapias Integrativas",
          "slug": "terapias_integrativas",
        },
        {
          "id": "668ed5a2c589a1b2c3d4e5f5",
          "name": "Inteligência Emocional",
          "slug": "inteligencia-emocional",
        },
      ],
      "teachers": [
        {
          "id": fakeMongoId,
          "name": "Tadashi Kadomoto",
          "avatar_url":
              "https://www.fenaclubes.com.br/wp-content/uploads/2023/04/tadashi-kadomoto.jpg",
          "highlight": true,
        },
      ],
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

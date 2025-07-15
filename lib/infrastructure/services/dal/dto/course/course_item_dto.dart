import 'package:unifast_portal/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_childrens_summary_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_content_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_summary_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/teacher_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/files_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/thumb_dto.dart';

class CourseItemDetailsDTO {
  String id;
  String title;
  String description;
  ThumbDTO thumb;
  List<TeacherDTO> teachers;
  List<CategoryDTO>? categories;
  CourseItemSummaryDTO? previous;
  CourseItemSummaryDTO? next;
  CourseChildrensSummaryDTO? childrensSummary;
  List<CourseItemSummaryDTO> childrens;
  List<FileDTO> files;
  CourseContentDTO? content;

  CourseItemDetailsDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
    required this.categories,
    required this.teachers,
    required this.childrensSummary,
    required this.childrens,
    required this.files,
    this.previous,
    this.next,
    this.content,
  }) : assert(
         content != null || (childrens.isNotEmpty),
         "CourseItemDetails should have content or at least one child.",
       );

  factory CourseItemDetailsDTO.fromJson(Map<String, dynamic> json) {
    final _id = json['id'] as String;
    final _title = json['title'] as String;
    final _description = json['description'] as String;
    final _thumb = ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>);
    final _teachers = (json['teachers'] as List)
        .map((e) => TeacherDTO.fromJson(e as Map<String, dynamic>))
        .toList();
    final _categories = (json['categories'] as List?)
        ?.map((e) => CategoryDTO.fromJson(e as Map<String, dynamic>))
        .toList();

    final _files =
        (json['files'] as List?)
            ?.map((e) => FileDTO.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    CourseChildrensSummaryDTO? _childrensSummary;
    final _childrensSummaryRaw = json['childrens'] as Map<String, dynamic>?;

    if (_childrensSummaryRaw != null && _childrensSummaryRaw['meta'] != null) {
      _childrensSummary = CourseChildrensSummaryDTO.fromJson(
        _childrensSummaryRaw['meta'],
      );
    }

    final _childrens = json['childrens'] != null
        ? (json['childrens']['items'] as List)
              .map(
                (e) => CourseItemSummaryDTO.fromJson(e as Map<String, dynamic>),
              )
              .toList()
        : <CourseItemSummaryDTO>[];

    final _content = json['content'] != null
        ? CourseContentDTO.fromJson(json['content'] as Map<String, dynamic>)
        : null;

    final _next = json['next'] != null
        ? CourseItemSummaryDTO.fromJson(json['next'] as Map<String, dynamic>)
        : null;

    final _previous = json['previous'] != null
        ? CourseItemSummaryDTO.fromJson(json['previous'] as Map<String, dynamic>)
        : null;

    return CourseItemDetailsDTO(
      id: _id,
      title: _title,
      description: _description,
      thumb: _thumb,
      categories: _categories,
      teachers: _teachers,
      childrensSummary: _childrensSummary,
      childrens: _childrens,
      files: _files,
      next: _next,
      previous: _previous,
      content: _content,
    );
  }
}

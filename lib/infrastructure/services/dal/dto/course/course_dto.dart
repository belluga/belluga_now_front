import 'package:unifast_portal/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_childrens_summary_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_content_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_type_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/teacher_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/files_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/thumb_dto.dart';

class CourseDTO extends CourseItemDTO {
  CourseTypeDTO type;

  CourseDTO({
    required super.id,
    required super.title,
    required this.type,
    required super.description,
    required super.thumb,
    required super.categories,
    required super.teachers,
    required super.childrensSummary,
    required super.childrens,
    required super.files,
    required super.content,
  });

  factory CourseDTO.fromJson(Map<String, dynamic> json) {
    return CourseDTO(
      id: json['id'] as String,
      title: json['title'] as String,
      type: CourseTypeDTO.fromJson(json['type'] as Map<String, dynamic>),
      description: json['description'] as String,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
      categories: (json['categories'] as List?)
          ?.map((e) => CategoryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      teachers: (json['teachers'] as List)
          .map((e) => TeacherDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      childrensSummary: CourseChildrensSummaryDTO.fromJson(
        json['childrens']['meta'],
      ),
      childrens: (json['childrens']['items'] as List)
          .map((e) => CourseItemDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      files:
          (json['files'] as List?)
              ?.map((e) => FileDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      content: json['content'] != null
          ? CourseContentDTO.fromJson(json['content'])
          : null,
    );
  }
}

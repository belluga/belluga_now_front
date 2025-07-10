import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_childrens_summary_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_content_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/teacher_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/files_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/thumb_dto.dart';

class CourseItemDTO {
  String id;
  String title;
  String description;
  ThumbDTO thumb;
  List<TeacherDTO> teachers;
  CourseChildrensSummaryDTO childrensSummary;
  List<CourseItemDTO> childrens;
  List<FileDTO> files;
  CourseContentDTO? content;

  CourseItemDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
    required this.teachers,
    required this.childrensSummary,
    required this.childrens,
    required this.files,
    this.content,
  });

  factory CourseItemDTO.fromJson(Map<String, dynamic> json) {
    return CourseItemDTO(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
      teachers: (json['teachers'] as List)
          .map((e) => TeacherDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      childrensSummary: json['childrens'] != null
          ? CourseChildrensSummaryDTO.fromJson(json['childrens']['meta'])
          : CourseChildrensSummaryDTO.empty(),
      childrens: json['childrens'] != null
          ? (json['childrens']['items'] as List)
                .map((e) => CourseItemDTO.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
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

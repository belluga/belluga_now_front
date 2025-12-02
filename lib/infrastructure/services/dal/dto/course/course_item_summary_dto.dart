import 'package:belluga_now/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/teacher_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/thumb_dto.dart';

class CourseItemSummaryDTO {
  String id;
  String title;
  String description;
  ThumbDTO thumb;
  List<TeacherDTO> teachers;
  List<CategoryDTO>? categories;

  CourseItemSummaryDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
    required this.categories,
    required this.teachers,
  });

  factory CourseItemSummaryDTO.fromJson(Map<String, dynamic> json) {
    return CourseItemSummaryDTO(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
      categories: (json['categories'] as List?)
          ?.map((e) => CategoryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      teachers: ((json['teachers'] as List?) ?? [])
          .map((e) => TeacherDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/category_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_items_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/lesson_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/expert_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/thumb_dto.dart';

class CourseDTO {
  String id;
  String title;
  String type;
  String description;
  ThumbDTO thumb;
  List<CategoryDto> categories;
  ExpertDTO expert;
  CourseItemsSummaryDTO disciplinesSummary;
  List<LessonDTO> disciplines;

  CourseDTO({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.thumb,
    required this.categories,
    required this.expert,
    required this.disciplinesSummary,
    required this.disciplines,
  });

  factory CourseDTO.fromJson(Map<String, dynamic> json) {
    return CourseDTO(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
      categories: (json['categories'] as List)
          .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      expert: ExpertDTO.fromJson(json['expert'] as Map<String, dynamic>),
      disciplinesSummary:
          CourseItemsSummaryDTO.fromJson(json['disciplines']['summary']),
      disciplines: (json['disciplines']['items'] as List)
          .map((e) => LessonDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
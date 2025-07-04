import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_items_summary_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/lesson_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/thumb_dto.dart';

class DisciplineDTO {
  String id;
  String title;
  String description;
  ThumbDTO thumb;
  CourseItemsSummaryDTO lessonsSummary;
  List<LessonDTO> lessons;

  DisciplineDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
    required this.lessonsSummary,
    required this.lessons,
  });

  factory DisciplineDTO.fromJson(Map<String, dynamic> json) {
    return DisciplineDTO(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
      lessonsSummary: CourseItemsSummaryDTO.fromJson(
        json['lesspns']["summary"] as Map<String, dynamic>,
      ),
      lessons: (json['lessons']['items'] as List)
          .map((item) => LessonDTO.fromJson(item))
          .toList(),
    );
  }
}

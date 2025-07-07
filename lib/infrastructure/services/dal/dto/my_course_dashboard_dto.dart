import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_type_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_course_dashboard_lesson_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/expert_dto.dart';

class MyCourseDashboardDTO {
  final String id;
  final String title;
  final CourseTypeDTO type;
  final String description;
  final String thumbUrl;
  final ExpertDTO expert;
  final MyCourseDashboardLessonDto nextLesson;

  MyCourseDashboardDTO({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.thumbUrl,
    required this.expert,
    required this.nextLesson,
  });

  factory MyCourseDashboardDTO.fromJson(Map<String, Object?> map) {
    final _id = map['id'] as String;
    final _title = map['title'] as String;
    final _expert = ExpertDTO.fromJson(map['expert'] as Map<String, dynamic>);
    final _type = CourseTypeDTO.fromJson(map['type'] as Map<String, dynamic>);
    final _description = map['description'] as String;
    final _thumb = map['thumb_url'] as String;
    final _nextLesson = MyCourseDashboardLessonDto.fromJson(
      map['next_lesson'] as Map<String, dynamic>,
    );

    return MyCourseDashboardDTO(
      id: _id,
      title: _title,
      type: _type,
      description: _description,
      thumbUrl: _thumb,
      expert: _expert,
      nextLesson: _nextLesson,
    );
  }
}

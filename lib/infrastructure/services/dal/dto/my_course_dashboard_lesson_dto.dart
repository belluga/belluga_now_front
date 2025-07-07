import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/thumb_dto.dart';

class MyCourseDashboardLessonDto {
  final String id;
  final String title;
  final String description;
  final ThumbDTO thumb;

  MyCourseDashboardLessonDto({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
  });

  factory MyCourseDashboardLessonDto.fromJson(Map<String, Object?> map) {
    final _id = map['id'] as String;
    final _thumb = ThumbDTO.fromJson(map['thumb'] as Map<String, dynamic>);
    final _title = map['title'] as String;
    final _description = map['description'] as String;

    return MyCourseDashboardLessonDto(
      id: _id,
      title: _title,
      description: _description,
      thumb: _thumb,
    );
  }
}

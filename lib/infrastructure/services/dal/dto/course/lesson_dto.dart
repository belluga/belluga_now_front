import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/files_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/lesson_content_dto.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/thumb_dto.dart';

class LessonDTO {
  String id;
  String title;
  String description;
  ThumbDTO thumb;
  int durationInSeconds;
  List<FilesDTO> files;
  LessonContentDTO content;

  LessonDTO({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
    required this.durationInSeconds,
    required this.files,
    required this.content,
  });

  factory LessonDTO.fromJson(Map<String, dynamic> json) {
    return LessonDTO(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      thumb: ThumbDTO.fromJson(json['thumb'] as Map<String, dynamic>),
      durationInSeconds: json['duration_in_seconds'] as int,
      files: (json['files'] as List)
          .map((e) => FilesDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      content: LessonContentDTO.fromJson(
        json['content'] as Map<String, dynamic>,
      ),
    );
  }
}

import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/video_dto.dart';

class LessonContentDTO {
  final VideoDTO video;
  final String? htmlContent;

  LessonContentDTO({
    required this.video,
    this.htmlContent,
  });

  factory LessonContentDTO.fromJson(Map<String, dynamic> json) {
    return LessonContentDTO(
      video: VideoDTO.fromJson(json['video'] as Map<String, dynamic>),
      htmlContent: json['html']?['content'] as String?,
    );
  }
}
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/video_dto.dart';

class CourseContentDTO {
  final VideoDTO video;
  final String? htmlContent;

  CourseContentDTO({
    required this.video,
    this.htmlContent,
  });

  factory CourseContentDTO.fromJson(Map<String, dynamic> json) {
    return CourseContentDTO(
      video: VideoDTO.fromJson(json['video'] as Map<String, dynamic>),
      htmlContent: json['html']?['content'] as String?,
    );
  }
}
import 'package:flutter_laravel_backend_boilerplate/domain/courses/video_model.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_content_dto.dart';
import 'package:value_objects/domain/value_objects/generic_string_value.dart';

class CourseContentModel {
  final VideoModel video;
  final GenericStringValue html;

  CourseContentModel({required this.video, required this.html});

  factory CourseContentModel.fromDTO(CourseContentDTO lesson) {
    final _video = VideoModel.fromDTO(lesson.video);
    final _html = GenericStringValue()..tryParse(lesson.htmlContent);

    return CourseContentModel(video: _video, html: _html);
  }
}

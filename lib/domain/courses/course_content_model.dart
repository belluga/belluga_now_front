import 'package:unifast_portal/domain/courses/video_model.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_content_dto.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/video_dto.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class CourseContentModel {
  final VideoModel? video;
  final GenericStringValue? html;

  CourseContentModel({required this.video, required this.html})
    : assert(
        video != null || html != null,
        "Either video or html should not be null",
      );

  factory CourseContentModel.fromDTO(CourseContentDTO lesson) {
    final VideoDTO? _videoDTO = lesson.video;
    final _video = _videoDTO != null ? VideoModel.fromDTO(_videoDTO) : null;

    final String? _htmlContentRaw = lesson.htmlContent;
    final _html = _htmlContentRaw != null
        ? (GenericStringValue()..parse(_htmlContentRaw))
        : null;

    return CourseContentModel(video: _video, html: _html);
  }
}

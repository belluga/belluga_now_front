import 'package:belluga_now/infrastructure/services/dal/dto/course/video_dto.dart';

class CourseContentDTO {
  final VideoDTO? video;
  final String? htmlContent;

  CourseContentDTO({required this.video, this.htmlContent})
      : assert(
          video != null || htmlContent != null,
          "video or htmlContent should not be null",
        );

  factory CourseContentDTO.fromJson(Map<String, dynamic> json) {
    final _video = VideoDTO.fromJson(json['video'] as Map<String, dynamic>);
    final _htmlContent = json['html']?['content'] as String?;

    return CourseContentDTO(video: _video, htmlContent: _htmlContent);
  }
}

import 'package:belluga_now/domain/courses/video_model.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class CourseContentModel {
  final VideoModel? video;
  final GenericStringValue? html;

  CourseContentModel({required this.video, required this.html})
      : assert(
          video != null || html != null,
          'Either video or html should not be null',
        );
}

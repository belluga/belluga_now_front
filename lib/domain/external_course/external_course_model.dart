import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_description_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_initial_password_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_platform_uri_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_title_value.dart';

class ExternalCourseModel {
  final ThumbModel thumb;
  final ExternalCourseTitleValue title;
  final ExternalCourseDescriptionValue description;
  final ExternalCoursePlatformUriValue platformUrl;
  final ExternalCourseInitialPasswordValue initialPassword;

  ExternalCourseModel({
    required this.title,
    required this.description,
    required this.platformUrl,
    required this.thumb,
    required this.initialPassword,
  });
}

import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_description_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_initial_password_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_platform_uri_value.dart';
import 'package:belluga_now/domain/external_course/value_objects/external_course_title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/external_course_dto.dart';

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

  factory ExternalCourseModel.fromDTO(ExternalCourseDTO externalCourse) {
    final _thumbValue = ThumbModel.fromDTO(externalCourse.thumb);

    final _titleValue = ExternalCourseTitleValue()
      ..tryParse(externalCourse.title);

    final _description = ExternalCourseDescriptionValue()
      ..tryParse(externalCourse.description);

    final _platformUrl = ExternalCoursePlatformUriValue(
      defaultValue: Uri.parse(
        "https://media.istockphoto.com/id/1128826884/pt/vetorial/no-image-vector-symbol-missing-available-icon-no-gallery-for-this-moment.jpg?s=1024x1024&w=is&k=20&c=9vW4OtrgvQA6hfnIvdk-tQK0CPvlKyWTPh10p064u9k=",
      ),
    )..tryParse(externalCourse.platformUrl);

    final _initialPassword = ExternalCourseInitialPasswordValue()
      ..tryParse(externalCourse.initialPassword);

    return ExternalCourseModel(
      thumb: _thumbValue,
      title: _titleValue,
      description: _description,
      platformUrl: _platformUrl,
      initialPassword: _initialPassword,
    );
  }
}

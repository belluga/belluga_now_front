import 'package:flutter_laravel_backend_boilerplate/domain/external_course/value_objects/external_course_description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/external_course/value_objects/external_course_initial_password_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/external_course/value_objects/external_course_platform_uri_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/external_course/value_objects/external_course_thumb_uri_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/external_course/value_objects/external_course_title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/external_course_dashboard_dto.dart';

class ExternalCourseDashboard {
  final ExternalCourseThumbUriValue thumbUrl;
  final ExternalCourseTitleValue title;
  final ExternalCourseDescriptionValue description;
  final ExternalCoursePlatformUriValue platformUrl;
  final ExternalCourseInitialPasswordValue initialPassword;

  ExternalCourseDashboard({
    required this.title,
    required this.description,
    required this.platformUrl,
    required this.thumbUrl,
    required this.initialPassword,
  });

  factory ExternalCourseDashboard.fromDTO(ExternalCourseDashboardDTO externalCourse) {
    final _thumbValue = ExternalCourseThumbUriValue(defaultValue: Uri.parse("https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308"))
      ..tryParse(externalCourse.thumUrl);

    final _titleValue = ExternalCourseTitleValue()
      ..tryParse(externalCourse.title);

    final _description = ExternalCourseDescriptionValue()
      ..tryParse(externalCourse.description);

    final _platformUrl = ExternalCoursePlatformUriValue(defaultValue: Uri.parse("https://media.istockphoto.com/id/1128826884/pt/vetorial/no-image-vector-symbol-missing-available-icon-no-gallery-for-this-moment.jpg?s=1024x1024&w=is&k=20&c=9vW4OtrgvQA6hfnIvdk-tQK0CPvlKyWTPh10p064u9k="))
      ..tryParse(externalCourse.platformUrl);

    final _initialPassword = ExternalCourseInitialPasswordValue()
      ..tryParse(externalCourse.initialPassword);

    return ExternalCourseDashboard(
      thumbUrl: _thumbValue,
      title: _titleValue,
      description: _description,
      platformUrl: _platformUrl,
      initialPassword: _initialPassword,
    );
  }
}

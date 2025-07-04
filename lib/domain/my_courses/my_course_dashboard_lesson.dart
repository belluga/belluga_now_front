import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_thumb_uri_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_course_dashboard_lesson_dto.dart';

class MyCourseDashboardLesson {
  final MyCourseThumbUriValue thumbUrl;
  final MyCourseTitleValue title;
  final MyCourseDescriptionValue description;
  

  MyCourseDashboardLesson({
    required this.title,
    required this.description,
    required this.thumbUrl,
  });

  factory MyCourseDashboardLesson.fromDTO(MyCourseDashboardLessonDto lesson) {
    final _thumbValue = MyCourseThumbUriValue(defaultValue: Uri.parse("https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308"))
      ..tryParse(lesson.thumbUrl);

    final _titleValue = MyCourseTitleValue()
      ..tryParse(lesson.title);

    final _description = MyCourseDescriptionValue()
      ..tryParse(lesson.description);

    return MyCourseDashboardLesson(
      thumbUrl: _thumbValue,
      title: _titleValue,
      description: _description,
    );
  }
}

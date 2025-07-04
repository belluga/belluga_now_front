import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/my_course_dashboard_expert.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/my_course_dashboard_lesson.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_thumb_uri_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/value_objects/my_course_type_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_course_dashboard_dto.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class MyCourseDashboard {
  final MongoIDValue id;
  final MyCourseTitleValue title;
  final MyCourseTypeValue type;
  final MyCourseDescriptionValue description;
  final MyCourseThumbUriValue thumbUrl;
  final MyCourseDashboardExpert expert;
  final MyCourseDashboardLesson nextLesson;

  MyCourseDashboard({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.thumbUrl,
    required this.expert,
    required this.nextLesson,
  });

  factory MyCourseDashboard.fromDTO(MyCourseDashboardDTO myCourse) {
    final _idValue = MongoIDValue()..parse(myCourse.id);
    final _titleValue = MyCourseTitleValue()..tryParse(myCourse.title);
    final _typeValue = MyCourseTypeValue()..tryParse(myCourse.type);
    final _description = MyCourseDescriptionValue()
      ..tryParse(myCourse.description);
    final _thumbUrl = MyCourseThumbUriValue(
      defaultValue: Uri.parse(
        "https://www.istockphoto.com/br/vetor/sem-imagem-dispon%C3%ADvel-espa%C3%A7o-de-vis%C3%A3o-design-de-ilustra%C3%A7%C3%A3o-do-%C3%ADcone-da-miniatura-gm1409329028-459910308",
      ),
    )..tryParse(myCourse.thumbUrl);

    final _expert = MyCourseDashboardExpert.fromDTO(myCourse.expert);
    final _nextLesson = MyCourseDashboardLesson.fromDTO(myCourse.nextLesson);

    return MyCourseDashboard(
      id: _idValue,
      title: _titleValue,
      expert: _expert,
      type: _typeValue,
      thumbUrl: _thumbUrl,
      description: _description,
      nextLesson: _nextLesson,
    );
  }
}

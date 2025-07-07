import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_type_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/expert_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/thumb_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_course_dashboard_dto.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class CourseDashboardModel {
  final MongoIDValue id;
  final TitleValue title;
  final CourseTypeModel type;
  final DescriptionValue description;
  final ThumbModel thumb;
  final ExpertModel expert;

  CourseDashboardModel({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.thumb,
    required this.expert,
  });

  factory CourseDashboardModel.fromDTO(MyCourseDashboardDTO myCourse) {
    final _idValue = MongoIDValue()..parse(myCourse.id);
    final _titleValue = TitleValue()..tryParse(myCourse.title);
    final _typeValue = CourseTypeModel.fromDto(myCourse.type);
    final _description = DescriptionValue()
      ..tryParse(myCourse.description);
    final _thumb = ThumbModel.fromDTO(myCourse.thumb);

    final _expert = ExpertModel.fromDTO(myCourse.expert);

    return CourseDashboardModel(
      id: _idValue,
      title: _titleValue,
      expert: _expert,
      type: _typeValue,
      thumb: _thumb,
      description: _description,
    );
  }
}

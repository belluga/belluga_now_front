import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_items_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/lesson_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/thumb_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/discipline_dto.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class DisciplineModel {
  final MongoIDValue id;
  final TitleValue title;
  final DescriptionValue description;
  final ThumbModel thumb;
  final CourseItemsSummary lessonsSummary;
  final List<LessonModel> lessons;

  DisciplineModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
    required this.lessonsSummary,
    required this.lessons,
  });

  factory DisciplineModel.fromDTO(DisciplineDTO disciplineDTO) {
    final _id = MongoIDValue()..parse(disciplineDTO.id);
    final _title = TitleValue()..parse(disciplineDTO.title);
    final _description = DescriptionValue()..parse(disciplineDTO.title);
    final _thumb = ThumbModel.fromDTO(disciplineDTO.thumb);
    final _lessonsSummary = CourseItemsSummary.fromDTO(
      disciplineDTO.lessonsSummary,
    );
    final _lessons = disciplineDTO.lessons
        .map((item) => LessonModel.fromDTO(item))
        .toList();

    return DisciplineModel(
      id: _id,
      title: _title,
      description: _description,
      thumb: _thumb,
      lessonsSummary: _lessonsSummary,
      lessons: _lessons,
    );
  }
}

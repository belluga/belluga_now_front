import 'package:flutter_laravel_backend_boilerplate/domain/courses/thumb_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/lesson_dto.dart';

class LessonModel {
  final ThumbModel thumb;
  final TitleValue title;
  final DescriptionValue description;
  

  LessonModel({
    required this.title,
    required this.description,
    required this.thumb,
  });

  factory LessonModel.fromDTO(LessonDTO lesson) {
    final _thumb = ThumbModel.fromDTO(lesson.thumb);

    final _titleValue = TitleValue()
      ..tryParse(lesson.title);

    final _description = DescriptionValue()
      ..tryParse(lesson.description);

    return LessonModel(
      thumb: _thumb,
      title: _titleValue,
      description: _description,
    );
  }
}

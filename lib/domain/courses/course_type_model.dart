import 'package:flutter_laravel_backend_boilerplate/domain/courses/value_objects/slug_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_type_dto.dart';
import 'package:value_objects/domain/value_objects/mongo_id_value.dart';

class CourseTypeModel {
  MongoIDValue id;
  TitleValue name;
  SlugValue slug;

  CourseTypeModel({required this.id, required this.name, required this.slug});

  factory CourseTypeModel.fromDto(CourseTypeDTO dto) {

    final _id = MongoIDValue()..parse(dto.id);
    final _name = TitleValue()..parse(dto.name);
    final _slug = SlugValue()..parse(dto.slug);

    return CourseTypeModel(id: _id, name: _name, slug: _slug);
  }
}

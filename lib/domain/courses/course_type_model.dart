import 'package:unifast_portal/domain/courses/value_objects/category_name.dart';
import 'package:unifast_portal/domain/courses/value_objects/slug_value.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_type_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class CourseTypeModel {
  MongoIDValue id;
  CategoryNameValue name;
  SlugValue slug;

  CourseTypeModel({required this.id, required this.name, required this.slug});

  factory CourseTypeModel.fromDto(CourseTypeDTO dto) {
    final _id = MongoIDValue()..parse(dto.id);
    final _name = CategoryNameValue()..parse(dto.name);
    final _slug = SlugValue()..parse(dto.slug);

    return CourseTypeModel(id: _id, name: _name, slug: _slug);
  }
}

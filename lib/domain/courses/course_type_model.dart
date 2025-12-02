import 'package:belluga_now/domain/courses/value_objects/category_name.dart';
import 'package:belluga_now/domain/courses/value_objects/slug_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class CourseTypeModel {
  MongoIDValue id;
  CategoryNameValue name;
  SlugValue slug;

  CourseTypeModel({
    required this.id,
    required this.name,
    required this.slug,
  });
}

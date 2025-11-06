import 'package:belluga_now/domain/courses/course_category_model.dart';
import 'package:belluga_now/domain/courses/teacher_model.dart';
import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class CourseBaseModel {
  final MongoIDValue id;
  final TitleValue title;
  final DescriptionValue description;
  final ThumbModel thumb;
  final List<TeacherModel> teachers;
  final List<CourseCategoryModel>? categories;

  CourseBaseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
    required this.categories,
    required this.teachers,
  });
}

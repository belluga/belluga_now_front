import 'package:unifast_portal/domain/courses/course_category_model.dart';
import 'package:unifast_portal/domain/courses/teacher_model.dart';
import 'package:unifast_portal/domain/courses/thumb_model.dart';
import 'package:unifast_portal/domain/value_objects/description_value.dart';
import 'package:unifast_portal/domain/value_objects/title_value.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_summary_dto.dart';
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

  factory CourseBaseModel.fromDto(CourseItemSummaryDTO dto) {
    final _id = MongoIDValue()..parse(dto.id);
    final _title = TitleValue()..parse(dto.title);
    final _description = DescriptionValue()..parse(dto.description);
    final _thumb = ThumbModel.fromDTO(dto.thumb);
    final _categories = dto.categories
        ?.map((item) => CourseCategoryModel.fromDto(item))
        .toList();

    final _teachers = dto.teachers
        .map((item) => TeacherModel.fromDTO((item)))
        .toList();

    return CourseBaseModel(
      id: _id,
      title: _title,
      description: _description,
      thumb: _thumb,
      categories: _categories,
      teachers: _teachers,
    );
  }
}

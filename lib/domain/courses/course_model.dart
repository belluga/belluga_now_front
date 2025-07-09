import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_category_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_content_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_item_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_items_summary.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_type_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/file_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/teacher_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/courses/thumb_model.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/description_value.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/value_objects/title_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class CourseModel extends CourseItemModel {
  final CourseTypeModel type;
  final List<CourseCategoryModel> categories;

  CourseModel({
    required super.id,
    required super.title,
    required this.type,
    required super.description,
    required super.thumb,
    required this.categories,
    required super.teachers,
    required super.childrensSummary,
    required super.childrens,
    required super.files,
    required super.content,
  });

  factory CourseModel.fromDto(CourseDTO dto) {
    final _id = MongoIDValue()..parse(dto.id);
    final _title = TitleValue()..parse(dto.title);
    final _type = CourseTypeModel.fromDto(dto.type);
    final _description = DescriptionValue()..parse(dto.description);
    final _thumb = ThumbModel.fromDTO(dto.thumb);
    final _categories = dto.categories
        .map((item) => CourseCategoryModel.fromDto(item))
        .toList();

    final _teachers = dto.teachers
        .map((item) => TeacherModel.fromDTO((item)))
        .toList();

    final _childrensSummary = CourseChildrensSummary.fromDTO(
      dto.childrensSummary,
    );

    final _childrens = dto.childrens
        .map((item) => CourseItemModel.fromDto((item)))
        .toList();

    final _files = dto.files.map((item) => FileModel.fromDTO((item))).toList();

    final _contentDto = dto.content;
    final _content = _contentDto != null
        ? CourseContentModel.fromDTO(_contentDto)
        : null;

    return CourseModel(
      id: _id,
      title: _title,
      type: _type,
      description: _description,
      thumb: _thumb,
      categories: _categories,
      teachers: _teachers,
      childrensSummary: _childrensSummary,
      childrens: _childrens,
      files: _files,
      content: _content,
    );
  }
}

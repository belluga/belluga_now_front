import 'package:unifast_portal/domain/courses/course_category_model.dart';
import 'package:unifast_portal/domain/courses/course_content_model.dart';
import 'package:unifast_portal/domain/courses/course_items_summary.dart';
import 'package:unifast_portal/domain/courses/file_model.dart';
import 'package:unifast_portal/domain/courses/teacher_model.dart';
import 'package:unifast_portal/domain/courses/thumb_model.dart';
import 'package:unifast_portal/domain/value_objects/description_value.dart';
import 'package:unifast_portal/domain/value_objects/title_value.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/course/course_item_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class CourseItemModel {
  final MongoIDValue id;
  final TitleValue title;
  final DescriptionValue description;
  final ThumbModel thumb;
  final List<TeacherModel> teachers;
  final CourseChildrensSummary childrensSummary;
  final List<CourseItemModel> childrens;
  final List<FileModel> files;
  final List<CourseCategoryModel>? categories;
  final CourseContentModel? content;

  CourseItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumb,
    required this.teachers,
    required this.categories,
    required this.childrensSummary,
    required this.childrens,
    required this.files,
    required this.content,
  });

  bool get hasContent => content != null;
  bool get hasVideoContent => content?.video != null;
  bool get hasHtmlContent => content?.html != null;

  factory CourseItemModel.fromDto(CourseItemDTO dto) {
    final _id = MongoIDValue()..parse(dto.id);
    final _title = TitleValue()..parse(dto.title);
    final _description = DescriptionValue()..parse(dto.description);
    final _thumb = ThumbModel.fromDTO(dto.thumb);

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

    final _categories = dto.categories
        ?.map((item) => CourseCategoryModel.fromDto(item))
        .toList();

    final _contentDto = dto.content;
    final _content = _contentDto != null
        ? CourseContentModel.fromDTO(_contentDto)
        : null;

    return CourseItemModel(
      id: _id,
      title: _title,
      description: _description,
      thumb: _thumb,
      teachers: _teachers,
      categories: _categories,
      childrensSummary: _childrensSummary,
      childrens: _childrens,
      files: _files,
      content: _content,
    );
  }
}

import 'package:belluga_now/domain/courses/course_category_model.dart';
import 'package:belluga_now/domain/courses/course_content_model.dart';
import 'package:belluga_now/domain/courses/course_childrens_summary.dart';
import 'package:belluga_now/domain/courses/course_base_model.dart';
import 'package:belluga_now/domain/courses/file_model.dart';
import 'package:belluga_now/domain/courses/teacher_model.dart';
import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/course_childrens_summary_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/course_item_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class CourseItemModel {
  final MongoIDValue id;
  final TitleValue title;
  final DescriptionValue description;
  final ThumbModel thumb;
  final List<TeacherModel> teachers;
  final CourseBaseModel? next;
  final CourseBaseModel? parent;
  final CourseChildrensSummary? childrensSummary;
  final List<CourseBaseModel> childrens;
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
    this.next,
    this.parent,
  });

  bool get hasContent => content != null;
  bool get hasVideoContent => content?.video != null;
  bool get hasHtmlContent => content?.html != null;

  factory CourseItemModel.fromDto(CourseItemDetailsDTO dto) {
    final _id = MongoIDValue()..parse(dto.id);
    final _title = TitleValue()..parse(dto.title);
    final _description = DescriptionValue()..parse(dto.description);
    final _thumb = ThumbModel.fromDTO(dto.thumb);

    final _teachers = dto.teachers
        .map((item) => TeacherModel.fromDTO((item)))
        .toList();

    final CourseChildrensSummaryDTO? _childrensSummaryDto =
        dto.childrensSummary;
    final _childrensSummary = _childrensSummaryDto != null
        ? CourseChildrensSummary.fromDTO(_childrensSummaryDto)
        : null;

    final _childrens = dto.childrens
        .map((item) => CourseBaseModel.fromDto((item)))
        .toList();

    final _files = dto.files.map((item) => FileModel.fromDTO((item))).toList();

    final _categories = dto.categories
        ?.map((item) => CourseCategoryModel.fromDto(item))
        .toList();

    final _contentDto = dto.content;
    final _content = _contentDto != null
        ? CourseContentModel.fromDTO(_contentDto)
        : null;

    final _next = dto.next != null
        ? CourseBaseModel.fromDto(dto.next!)
        : null;

    final _parent = dto.parent != null
        ? CourseBaseModel.fromDto(dto.parent!)
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
      next: _next,
      parent: _parent,
    );
  }
}

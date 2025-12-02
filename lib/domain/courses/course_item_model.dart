import 'package:belluga_now/domain/courses/course_base_model.dart';
import 'package:belluga_now/domain/courses/course_category_model.dart';
import 'package:belluga_now/domain/courses/course_childrens_summary.dart';
import 'package:belluga_now/domain/courses/course_content_model.dart';
import 'package:belluga_now/domain/courses/file_model.dart';
import 'package:belluga_now/domain/courses/teacher_model.dart';
import 'package:belluga_now/domain/courses/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
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
}

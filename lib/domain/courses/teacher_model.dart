import 'package:belluga_now/domain/courses/value_objects/expert_name_value.dart';
import 'package:belluga_now/domain/courses/value_objects/teacher_is_highlight.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class TeacherModel {
  final ExpertNameValue name;
  final URIValue avatarUrl;
  final TeacherIsHighlight isHightlight;

  TeacherModel({
    required this.name,
    required this.avatarUrl,
    required this.isHightlight,
  });
}

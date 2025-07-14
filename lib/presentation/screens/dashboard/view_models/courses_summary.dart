import 'package:unifast_portal/domain/courses/course_base_model.dart';

class CoursesSummary {
  final int total;
  final List<CourseBaseModel> items;

  CoursesSummary({required this.total, required this.items});
}

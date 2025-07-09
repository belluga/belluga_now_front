import 'package:unifast_portal/domain/courses/course_model.dart';

class CoursesSummary {
  final int total;
  final List<CourseModel> items;

  CoursesSummary({required this.total, required this.items});
}

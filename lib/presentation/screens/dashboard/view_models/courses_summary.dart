import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_model.dart';

class CoursesSummary {
  final int total;
  final List<CourseModel> items;

  CoursesSummary({required this.total, required this.items});
}

import 'package:flutter_laravel_backend_boilerplate/domain/external_course/external_course_model.dart';

class ExternalCoursesSummary {
  final int total;
  final List<ExternalCourseModel> items;

  ExternalCoursesSummary({required this.total, required this.items});
}

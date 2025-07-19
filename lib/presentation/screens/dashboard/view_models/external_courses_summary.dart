import 'package:belluga_now/domain/external_course/external_course_model.dart';

class ExternalCoursesSummary {
  final int total;
  final List<ExternalCourseModel> items;

  ExternalCoursesSummary({required this.total, required this.items});
}

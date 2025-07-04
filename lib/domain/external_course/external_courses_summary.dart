import 'package:flutter_laravel_backend_boilerplate/domain/external_course/external_course_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/external_courses_summary_dto.dart';

class ExternalCoursesSummary {
  final int total;
  final List<ExternalCourseDashboard> items;

  ExternalCoursesSummary({
    required this.total,
    required this.items,
  });

  factory ExternalCoursesSummary.fromDTO(
    ExternalCoursesSummaryDTO externalCourseSummary,
  ) {
    final _total = externalCourseSummary.total;
    final _items = externalCourseSummary.items
        .map((item) => ExternalCourseDashboard.fromDTO(item))
        .toList();

    return ExternalCoursesSummary(total: _total, items: _items);
  }
}

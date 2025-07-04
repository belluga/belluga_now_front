import 'package:flutter_laravel_backend_boilerplate/domain/my_courses/my_course_dashboard.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_courses_summary_dto.dart';

class MyCoursesSummary {
  final int total;
  final List<MyCourseDashboard> items;

  MyCoursesSummary({
    required this.total,
    required this.items,
  });

  factory MyCoursesSummary.fromDTO(
    MyCoursesSummaryDTO externalCourseSummary,
  ) {
    final _total = externalCourseSummary.total;
    final _items = externalCourseSummary.items
        .map((item) => MyCourseDashboard.fromDTO(item))
        .toList();

    return MyCoursesSummary(total: _total, items: _items);
  }
}

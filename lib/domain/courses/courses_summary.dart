import 'package:flutter_laravel_backend_boilerplate/domain/courses/course_dashboard_model.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_courses_summary_dto.dart';

class CoursesSummary {
  final int total;
  final List<CourseDashboardModel> items;

  CoursesSummary({required this.total, required this.items});

  factory CoursesSummary.fromDTO(MyCoursesSummaryDTO externalCourseSummary) {
    final _total = externalCourseSummary.total;
    final _items = externalCourseSummary.items
        .map((item) => CourseDashboardModel.fromDTO(item))
        .toList();

    return CoursesSummary(total: _total, items: _items);
  }
}

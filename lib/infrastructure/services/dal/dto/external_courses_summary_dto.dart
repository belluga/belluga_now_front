import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/external_course_dashboard_dto.dart';

class ExternalCoursesSummaryDTO {
  final int total;
  final List<ExternalCourseDashboardDTO> items;

  ExternalCoursesSummaryDTO({required this.items, required this.total});

  factory ExternalCoursesSummaryDTO.fromJson(Map<String, Object?> map) {
    final _total = map['total'] as int;
    final _items = (map['data'] as List<Object?>)
        .map((item) => ExternalCourseDashboardDTO.fromJson(item as Map<String, Object?>))
        .toList();

    return ExternalCoursesSummaryDTO(items: _items, total: _total);
  }
}

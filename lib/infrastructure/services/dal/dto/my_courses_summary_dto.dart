
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/my_course_dashboard_dto.dart';

class MyCoursesSummaryDTO {
  final int total;
  final List<MyCourseDashboardDTO> items;

  MyCoursesSummaryDTO({required this.items, required this.total});

  factory MyCoursesSummaryDTO.fromMap(Map<String, Object?> map) {
    final _total = map['total'] as int;
    final _items = (map['data'] as List<Object?>)
        .map((item) => MyCourseDashboardDTO.fromMap(item as Map<String, Object?>))
        .toList();

    return MyCoursesSummaryDTO(items: _items, total: _total);
  }
}

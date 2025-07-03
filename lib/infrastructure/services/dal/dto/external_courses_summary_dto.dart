import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/external_course_dto.dart';

class ExternalCoursesSummaryDTO {
  final int total;
  final List<ExternalCourseDTO> items;

  ExternalCoursesSummaryDTO({required this.items, required this.total});

  factory ExternalCoursesSummaryDTO.fromMap(Map<String, Object?> map) {
    final _total = map['total'] as int;
    final _items = (map['data'] as List<Object?>)
        .map((item) => ExternalCourseDTO.fromMap(item as Map<String, Object?>))
        .toList();

    return ExternalCoursesSummaryDTO(items: _items, total: _total);
  }
}

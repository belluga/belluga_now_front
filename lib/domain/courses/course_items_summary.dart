import 'package:flutter_laravel_backend_boilerplate/domain/courses/value_objects/items_total_value.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/course/course_items_summary_dto.dart';

class CourseItemsSummary {
  ItemsTotalValue total;

  CourseItemsSummary({required this.total});

  factory CourseItemsSummary.fromDTO(CourseItemsSummaryDTO summaryDTO) {
    final _total = ItemsTotalValue()..parse(summaryDTO.total.toString());

    return CourseItemsSummary(total: _total);
  }
}

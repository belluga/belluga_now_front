import 'package:belluga_now/domain/courses/value_objects/items_total_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/course/course_childrens_summary_dto.dart';

class CourseChildrensSummary {
  final ItemsTotalValue total;
  final TitleValue label;

  CourseChildrensSummary({required this.total, required this.label});

  factory CourseChildrensSummary.fromDTO(CourseChildrensSummaryDTO summaryDTO) {
    final _total = ItemsTotalValue()..parse(summaryDTO.total.toString());
    final _label = TitleValue()..parse(summaryDTO.label);

    return CourseChildrensSummary(total: _total, label: _label);
  }
}

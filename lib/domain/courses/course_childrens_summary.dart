import 'package:belluga_now/domain/courses/value_objects/items_total_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class CourseChildrensSummary {
  final ItemsTotalValue total;
  final TitleValue label;

  CourseChildrensSummary({required this.total, required this.label});
}

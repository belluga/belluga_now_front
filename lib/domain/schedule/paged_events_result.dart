export 'value_objects/paged_events_result_values.dart';

import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

typedef PagedEventsResultPrimString = String;
typedef PagedEventsResultPrimInt = int;
typedef PagedEventsResultPrimDouble = double;
typedef PagedEventsResultPrimDateTime = DateTime;
typedef PagedEventsResultPrimDynamic = dynamic;

class PagedEventsResult {
  PagedEventsResult({
    required this.events,
    required this.hasMoreValue,
  });

  final List<EventModel> events;
  final DomainBooleanValue hasMoreValue;

  bool get hasMore => hasMoreValue.value;
}

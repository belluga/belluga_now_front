import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

PagedEventsResult pagedEventsResultFromRaw({
  required List<EventModel> events,
  required Object? hasMore,
}) {
  final hasMoreValue = DomainBooleanValue();
  hasMoreValue.parse(hasMore.toString());
  return PagedEventsResult(
    events: events,
    hasMoreValue: hasMoreValue,
  );
}

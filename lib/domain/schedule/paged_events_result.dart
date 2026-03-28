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
    required Object hasMore,
  }) : hasMoreValue = _parseHasMore(hasMore);

  final List<EventModel> events;
  final DomainBooleanValue hasMoreValue;

  bool get hasMore => hasMoreValue.value;

  static DomainBooleanValue _parseHasMore(Object raw) {
    if (raw is DomainBooleanValue) {
      return raw;
    }
    final value = DomainBooleanValue();
    value.parse(raw.toString());
    return value;
  }
}

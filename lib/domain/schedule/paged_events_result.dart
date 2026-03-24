import 'package:belluga_now/domain/schedule/event_model.dart';

typedef PagedEventsResultPrimString = String;
typedef PagedEventsResultPrimInt = int;
typedef PagedEventsResultPrimBool = bool;
typedef PagedEventsResultPrimDouble = double;
typedef PagedEventsResultPrimDateTime = DateTime;
typedef PagedEventsResultPrimDynamic = dynamic;

class PagedEventsResult {
  const PagedEventsResult({
    required this.events,
    required this.hasMore,
  });

  final List<EventModel> events;
  final PagedEventsResultPrimBool hasMore;
}

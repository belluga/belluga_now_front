import 'package:belluga_now/domain/schedule/event_model.dart';

class PagedEventsResult {
  const PagedEventsResult({
    required this.events,
    required this.hasMore,
  });

  final List<EventModel> events;
  final bool hasMore;
}

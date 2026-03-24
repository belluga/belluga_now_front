import 'package:belluga_now/domain/schedule/event_model.dart';

class HomeAgendaCacheSnapshot {
  const HomeAgendaCacheSnapshot({
    required this.events,
    required this.hasMore,
    required this.page,
    required this.showPastOnly,
    required this.searchQuery,
    required this.confirmedOnly,
    required this.capturedAt,
    this.originLat,
    this.originLng,
    this.maxDistanceMeters,
  });

  final List<EventModel> events;
  final bool hasMore;
  final int page;
  final bool showPastOnly;
  final String searchQuery;
  final bool confirmedOnly;
  final DateTime capturedAt;
  final double? originLat;
  final double? originLng;
  final double? maxDistanceMeters;
}

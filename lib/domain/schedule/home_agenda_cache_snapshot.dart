import 'package:belluga_now/domain/schedule/event_model.dart';

typedef HomeAgendaCacheSnapshotPrimString = String;
typedef HomeAgendaCacheSnapshotPrimInt = int;
typedef HomeAgendaCacheSnapshotPrimBool = bool;
typedef HomeAgendaCacheSnapshotPrimDouble = double;
typedef HomeAgendaCacheSnapshotPrimDateTime = DateTime;
typedef HomeAgendaCacheSnapshotPrimDynamic = dynamic;

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
  final HomeAgendaCacheSnapshotPrimBool hasMore;
  final HomeAgendaCacheSnapshotPrimInt page;
  final HomeAgendaCacheSnapshotPrimBool showPastOnly;
  final HomeAgendaCacheSnapshotPrimString searchQuery;
  final HomeAgendaCacheSnapshotPrimBool confirmedOnly;
  final HomeAgendaCacheSnapshotPrimDateTime capturedAt;
  final HomeAgendaCacheSnapshotPrimDouble? originLat;
  final HomeAgendaCacheSnapshotPrimDouble? originLng;
  final HomeAgendaCacheSnapshotPrimDouble? maxDistanceMeters;
}

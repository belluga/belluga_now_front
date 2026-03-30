import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_boolean_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_captured_at_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_page_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/home_agenda_search_query_value.dart';

class HomeAgendaCacheSnapshot {
  const HomeAgendaCacheSnapshot({
    required this.events,
    required this.hasMoreValue,
    required this.pageValue,
    required this.showPastOnlyValue,
    required this.searchQueryValue,
    required this.confirmedOnlyValue,
    required this.capturedAtValue,
    this.originLatValue,
    this.originLngValue,
    this.maxDistanceMetersValue,
  });

  final List<EventModel> events;
  final HomeAgendaBooleanValue hasMoreValue;
  final HomeAgendaPageValue pageValue;
  final HomeAgendaBooleanValue showPastOnlyValue;
  final HomeAgendaSearchQueryValue searchQueryValue;
  final HomeAgendaBooleanValue confirmedOnlyValue;
  final HomeAgendaCapturedAtValue capturedAtValue;
  final LatitudeValue? originLatValue;
  final LongitudeValue? originLngValue;
  final DistanceInMetersValue? maxDistanceMetersValue;

  bool get hasMore => hasMoreValue.value;
  int get page => pageValue.value;
  bool get showPastOnly => showPastOnlyValue.value;
  String get searchQuery => searchQueryValue.value;
  bool get confirmedOnly => confirmedOnlyValue.value;
  DateTime get capturedAt => capturedAtValue.value;
  double? get originLat => originLatValue?.value;
  double? get originLng => originLngValue?.value;
  double? get maxDistanceMeters => maxDistanceMetersValue?.value;
}

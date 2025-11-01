import 'package:belluga_now/domain/schedule/event_model.dart';

enum CityEventTemporalState { upcoming, now, past }

CityEventTemporalState resolveEventTemporalState(
  EventModel event, {
  DateTime? reference,
}) {
  final now = reference ?? DateTime.now();
  final start = event.dateTimeStart.value;
  final end = event.dateTimeEnd?.value;

  if (start == null) {
    return CityEventTemporalState.upcoming;
  }

  if (end != null) {
    if (now.isBefore(start)) {
      return CityEventTemporalState.upcoming;
    }
    if (now.isAfter(end)) {
      return CityEventTemporalState.past;
    }
    return CityEventTemporalState.now;
  }

  final diffMinutes = now.difference(start).inMinutes;
  if (diffMinutes >= 0 && diffMinutes <= 120) {
    return CityEventTemporalState.now;
  }
  if (diffMinutes > 120) {
    return CityEventTemporalState.past;
  }

  return CityEventTemporalState.upcoming;
}

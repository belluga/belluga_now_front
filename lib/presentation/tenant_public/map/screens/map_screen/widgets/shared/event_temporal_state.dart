import 'package:belluga_now/application/time/timezone_converter.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';

enum CityEventTemporalState { upcoming, now, past }

CityEventTemporalState resolveEventTemporalState(
  EventModel event, {
  DateTime? reference,
}) {
  final now = reference ?? DateTime.now();
  final startRaw = event.dateTimeStart.value;
  final endRaw = event.dateTimeEnd?.value;
  final start =
      startRaw == null ? null : TimezoneConverter.utcToLocal(startRaw);
  final end = endRaw == null ? null : TimezoneConverter.utcToLocal(endRaw);

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

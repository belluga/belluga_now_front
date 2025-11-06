import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/infrastructure/mappers/course_dto_mapper.dart';
import 'package:belluga_now/infrastructure/mappers/schedule_dto_mapper.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';

class ScheduleRepository extends ScheduleRepositoryContract
    with CourseDtoMapper, ScheduleDtoMapper {
  ScheduleRepository({ScheduleBackendContract? backend})
      : _backend = backend ?? GetIt.I.get<ScheduleBackendContract>();

  final ScheduleBackendContract _backend;
  List<EventDTO>? _cachedEvents;

  Future<List<EventDTO>> _loadEvents() async {
    if (_cachedEvents != null) {
      return _cachedEvents!;
    }
    final events = await _backend.fetchEvents();
    _cachedEvents = events;
    return events;
  }

  @override
  Future<List<EventModel>> getAllEvents() async {
    final events = await _loadEvents();
    return events.map(mapEvent).toList();
  }

  @override
  Future<List<EventModel>> getEventsByDate(DateTime date) async {
    final events = await getAllEvents();
    return events.where((event) {
      final eventDate = event.dateTimeStart.value;
      if (eventDate == null) {
        return false;
      }
      return eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day;
    }).toList();
  }

  @override
  Future<EventModel?> getEventBySlug(String slug) async {
    final normalizedSlug = _normalizeSlug(slug);
    final events = await getAllEvents();
    for (final event in events) {
      final idValue = event.id.value;
      if (idValue != null && idValue == slug) {
        return event;
      }

      final titleSlug = _normalizeSlug(event.title.value);
      if (titleSlug == normalizedSlug) {
        return event;
      }
    }
    return null;
  }

  String _normalizeSlug(String value) {
    final slug = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final cleaned = slug.replaceAll(RegExp(r'-{2,}'), '-');
    return cleaned.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    final summary = await _backend.fetchSummary();
    return mapScheduleSummary(summary);
  }
}

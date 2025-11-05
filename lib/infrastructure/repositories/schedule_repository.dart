import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:get_it/get_it.dart';

class ScheduleRepository extends ScheduleRepositoryContract {
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
    return events.map(EventModel.fromDTO).toList();
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
    final events = await _loadEvents();
    try {
      final dto = events.firstWhere((event) => event.id == slug);
      return EventModel.fromDTO(dto);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    final summary = await _backend.fetchSummary();
    return ScheduleSummaryModel.fromDTO(summary);
  }
}

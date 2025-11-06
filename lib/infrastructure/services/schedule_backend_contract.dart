import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_dto.dart';

abstract class ScheduleBackendContract {
  Future<EventSummaryDTO> fetchSummary();
  Future<List<EventDTO>> fetchEvents();
}

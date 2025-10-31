import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';

abstract class ScheduleRepositoryContract {
  Future<ScheduleSummaryModel> getScheduleSummary();
  Future<List<EventModel>> getEventsByDate(DateTime date);
  Future<List<EventModel>> getAllEvents();
}

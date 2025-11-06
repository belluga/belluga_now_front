import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:get_it/get_it.dart';

class EventDetailController {
  EventDetailController() : _repository = GetIt.I.get<ScheduleRepositoryContract>();

  final ScheduleRepositoryContract _repository;

  Future<EventModel?> loadEvent(String slug) {
    return _repository.getEventBySlug(slug);
  }
}

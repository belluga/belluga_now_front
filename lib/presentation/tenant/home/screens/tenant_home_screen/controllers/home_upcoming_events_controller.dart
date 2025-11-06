import 'dart:async';

import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class HomeUpcomingEventsController implements Disposable {
  HomeUpcomingEventsController();

  final ScheduleRepositoryContract _repository = GetIt.I.get<ScheduleRepositoryContract>();

  final StreamValue<List<EventModel>> upcomingEventsStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const []);

  Future<void> init() async {
    final events = await _repository.getAllEvents();
    final now = DateTime.now();

    final upcoming = events.where((event) {
      final date = event.dateTimeStart.value;
      if (date == null) {
        return false;
      }
      return date.isAfter(now.subtract(const Duration(hours: 1)));
    }).toList()
      ..sort(
        (a, b) {
          final aDate = a.dateTimeStart.value ?? DateTime(1970);
          final bDate = b.dateTimeStart.value ?? DateTime(1970);
          return aDate.compareTo(bDate);
        },
      );

    const limit = 6;
    upcomingEventsStreamValue.addValue(
      upcoming.length > limit ? upcoming.take(limit).toList() : upcoming,
    );
  }

  @override
  void onDispose() {
    upcomingEventsStreamValue.dispose();
  }
}

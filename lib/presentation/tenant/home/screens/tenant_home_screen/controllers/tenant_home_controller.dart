import 'dart:async';

import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantHomeController implements Disposable {
  TenantHomeController({
    FavoriteRepositoryContract? favoriteRepository,
    ScheduleRepositoryContract? scheduleRepository,
    UserEventsRepositoryContract? userEventsRepository,
  })  : _favoriteRepository =
            favoriteRepository ?? GetIt.I.get<FavoriteRepositoryContract>(),
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>();

  final FavoriteRepositoryContract _favoriteRepository;
  final ScheduleRepositoryContract _scheduleRepository;
  final UserEventsRepositoryContract _userEventsRepository;

  final StreamValue<List<FavoriteResume>?> favoritesStreamValue =
      StreamValue<List<FavoriteResume>?>();
  final StreamValue<List<VenueEventResume>?> myEventsStreamValue =
      StreamValue<List<VenueEventResume>?>();
  final StreamValue<List<VenueEventResume>> upcomingEventsStreamValue =
      StreamValue<List<VenueEventResume>>(defaultValue: const []);

  StreamValue<Set<String>> get confirmedSlugsStream =>
      _userEventsRepository.confirmedEventSlugsStream;

  StreamSubscription? _myEventsSubscription;

  Future<void> init() async {
    await Future.wait([
      loadFavorites(),
      loadMyEvents(),
      loadUpcomingEvents(),
    ]);

    // Listen for changes in confirmed events
    _myEventsSubscription =
        _userEventsRepository.confirmedEventSlugsStream.stream.listen((_) {
      loadMyEvents();
    });
  }

  Future<void> loadFavorites() async {
    final previousValue = favoritesStreamValue.value;
    favoritesStreamValue.addValue(null);
    try {
      final favorites = await _favoriteRepository.fetchFavoriteResumes();
      favoritesStreamValue.addValue(favorites);
    } catch (_) {
      favoritesStreamValue.addValue(previousValue);
    }
  }

  Future<void> loadMyEvents() async {
    final previousValue = myEventsStreamValue.value;
    // Don't set to null here to avoid flashing loading state on updates
    // myEventsStreamValue.addValue(null);
    try {
      final events = await _userEventsRepository.fetchMyEvents();
      myEventsStreamValue.addValue(events);
    } catch (_) {
      myEventsStreamValue.addValue(previousValue);
    }
  }

  Future<void> loadUpcomingEvents() async {
    try {
      final events = await _scheduleRepository.fetchUpcomingEvents();
      upcomingEventsStreamValue.addValue(events);
    } catch (_) {
      // keep last value; StreamValue already holds previous state
    }
  }

  @override
  void onDispose() {
    _myEventsSubscription?.cancel();
    favoritesStreamValue.dispose();
    myEventsStreamValue.dispose();
    upcomingEventsStreamValue.dispose();
  }
}

import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantHomeController implements Disposable {
  TenantHomeController({
    FavoriteRepositoryContract? favoriteRepository,
    ScheduleRepositoryContract? scheduleRepository,
  })  : _favoriteRepository =
            favoriteRepository ?? GetIt.I.get<FavoriteRepositoryContract>(),
        _scheduleRepository =
            scheduleRepository ?? GetIt.I.get<ScheduleRepositoryContract>();

  final FavoriteRepositoryContract _favoriteRepository;
  final ScheduleRepositoryContract _scheduleRepository;

  final StreamValue<List<FavoriteResume>?> favoritesStreamValue =
      StreamValue<List<FavoriteResume>?>();
  final StreamValue<List<VenueEventResume>?> featuredEventsStreamValue =
      StreamValue<List<VenueEventResume>?>();
  final StreamValue<List<VenueEventResume>> upcomingEventsStreamValue =
      StreamValue<List<VenueEventResume>>(defaultValue: const []);

  Future<void> init() async {
    await Future.wait([
      loadFavorites(),
      loadFeaturedEvents(),
      loadUpcomingEvents(),
    ]);
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

  Future<void> loadFeaturedEvents() async {
    final previousValue = featuredEventsStreamValue.value;
    featuredEventsStreamValue.addValue(null);
    try {
      final events = await _scheduleRepository.fetchFeaturedEvents();
      featuredEventsStreamValue.addValue(events);
    } catch (_) {
      featuredEventsStreamValue.addValue(previousValue);
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
    favoritesStreamValue.dispose();
    featuredEventsStreamValue.dispose();
    upcomingEventsStreamValue.dispose();
  }
}

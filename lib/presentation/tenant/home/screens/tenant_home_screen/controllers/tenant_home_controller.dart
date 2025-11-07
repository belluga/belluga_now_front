import 'package:belluga_now/domain/favorite/projections/favorite_resume.dart';
import 'package:belluga_now/domain/repositories/favorite_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/venue_event_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantHomeController implements Disposable {
  TenantHomeController();

  static final Uri _defaultEventImage = Uri.parse(
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800',
  );

  final _favoriteRepository = GetIt.I.get<FavoriteRepositoryContract>();
  final _venueEventRepository = GetIt.I.get<VenueEventRepositoryContract>();
  final _scheduleRepository = GetIt.I.get<ScheduleRepositoryContract>();

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
      final favorites = await _favoriteRepository.fetchFavorites();
      favoritesStreamValue.addValue(favorites);
    } catch (_) {
      favoritesStreamValue.addValue(previousValue);
    }
  }

  Future<void> loadFeaturedEvents() async {
    final previousValue = featuredEventsStreamValue.value;
    featuredEventsStreamValue.addValue(null);
    try {
      final events = await _venueEventRepository.fetchFeaturedEvents();
      featuredEventsStreamValue.addValue(events);
    } catch (_) {
      featuredEventsStreamValue.addValue(previousValue);
    }
  }

  Future<void> loadUpcomingEvents() async {
    try {
      final events = await _scheduleRepository.getAllEvents();
      final upcoming = _selectUpcoming(events);
      upcomingEventsStreamValue.addValue(upcoming);
    } catch (_) {
      // keep last value; StreamValue already holds previous state
    }
  }

  List<VenueEventResume> _selectUpcoming(List<EventModel> events) {
    final now = DateTime.now();
    final filtered = events.where((event) {
      final date = event.dateTimeStart.value;
      if (date == null) {
        return false;
      }
      return date.isAfter(now.subtract(const Duration(hours: 1)));
    }).toList()
      ..sort((a, b) {
        final aDate = a.dateTimeStart.value ?? DateTime(1970);
        final bDate = b.dateTimeStart.value ?? DateTime(1970);
        return aDate.compareTo(bDate);
      });

    const limit = 6;
    final limited =
        filtered.length > limit ? filtered.take(limit).toList() : filtered;

    return limited
        .map(
          (event) => VenueEventResume.fromScheduleEvent(
            event,
            _defaultEventImage,
          ),
        )
        .toList(growable: false);
  }

  @override
  void onDispose() {
    favoritesStreamValue.dispose();
    featuredEventsStreamValue.dispose();
    upcomingEventsStreamValue.dispose();
  }
}

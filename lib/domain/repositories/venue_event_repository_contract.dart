import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';

abstract class VenueEventRepositoryContract {
  Future<List<VenueEventResume>> fetchFeaturedEvents();

  /// Returns the next upcoming events already projected into [VenueEventResume].
  /// The repository is responsible for applying ordering/limiting semantics.
  Future<List<VenueEventResume>> fetchUpcomingEvents();
}

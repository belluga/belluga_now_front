import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';

abstract class VenueEventRepositoryContract {
  Future<List<VenueEventResume>> fetchFeaturedEvents();
}

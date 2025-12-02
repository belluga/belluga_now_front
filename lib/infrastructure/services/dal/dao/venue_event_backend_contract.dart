import 'package:belluga_now/infrastructure/services/dal/dto/venue_event/venue_event_preview_dto.dart';

abstract class VenueEventBackendContract {
  Future<List<VenueEventPreviewDTO>> fetchFeaturedEvents();
  Future<List<VenueEventPreviewDTO>> fetchUpcomingEvents();
}

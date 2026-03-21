import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/venue_event/venue_event_preview_dto.dart';

class LiveOnlyUnsupportedVenueEventBackend
    implements VenueEventBackendContract {
  const LiveOnlyUnsupportedVenueEventBackend();

  @override
  Future<List<VenueEventPreviewDTO>> fetchFeaturedEvents() {
    throw UnsupportedError(
      'Venue events backend adapter is not implemented for runtime yet.',
    );
  }

  @override
  Future<List<VenueEventPreviewDTO>> fetchUpcomingEvents() {
    throw UnsupportedError(
      'Venue events backend adapter is not implemented for runtime yet.',
    );
  }
}

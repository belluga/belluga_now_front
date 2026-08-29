import 'package:belluga_now/infrastructure/dal/dao/event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/event/event_preview_dto.dart';

class LiveOnlyUnsupportedEventBackend
    implements EventBackendContract {
  const LiveOnlyUnsupportedEventBackend();

  @override
  Future<List<EventPreviewDTO>> fetchFeaturedEvents() {
    throw UnsupportedError(
      'Events backend adapter is not implemented for runtime yet.',
    );
  }

  @override
  Future<List<EventPreviewDTO>> fetchUpcomingEvents() {
    throw UnsupportedError(
      'Events backend adapter is not implemented for runtime yet.',
    );
  }
}

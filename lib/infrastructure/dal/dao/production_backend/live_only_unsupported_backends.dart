import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/venue_event/venue_event_preview_dto.dart';

class LiveOnlyUnsupportedTenantBackend implements TenantBackendContract {
  const LiveOnlyUnsupportedTenantBackend();

  @override
  Future<Tenant> getTenant() {
    throw UnsupportedError(
      'Tenant backend adapter is not available in runtime. '
      'Tenant resolution must come from app bootstrap data.',
    );
  }
}

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

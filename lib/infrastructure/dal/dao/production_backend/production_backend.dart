import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/auth_backend/auth_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_favorite_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_tenant_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_venue_event_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';

class ProductionBackend extends BackendContract {
  @override
  final AuthBackendContract auth = LaravelAuthBackend();

  @override
  // TODO(Delphi): Replace with a Laravel tenant backend once the adapter exists.
  // Next: implement `TenantBackendContract` backed by `/api/v1/tenant` and wire it here.
  final TenantBackendContract tenant = MockTenantBackend();

  @override
  // TODO(Delphi): Replace with a Laravel favorites backend once the adapter exists.
  // Next: implement `FavoriteBackendContract` backed by favorites endpoints and wire it here.
  final FavoriteBackendContract favorites = MockFavoriteBackend();

  @override
  // TODO(Delphi): Replace with a Laravel venue events backend once the adapter exists.
  // Next: implement `VenueEventBackendContract` backed by `/api/v1/venue-events` and wire it here.
  final VenueEventBackendContract venueEvents = MockVenueEventBackend();

  @override
  // TODO(Delphi): Replace with a Laravel schedule backend once the adapter exists.
  // Next: implement `ScheduleBackendContract` backed by `/api/v1/schedule` and wire it here.
  final ScheduleBackendContract schedule = MockScheduleBackend();
}

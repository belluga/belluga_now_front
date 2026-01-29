import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_auth_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_favorite_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_partners_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_tenant_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_venue_event_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/partners_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';

class MockBackend extends BackendContract {
  BackendContext? _context;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  final AppDataBackendContract appData = AppDataBackend();

  @override
  final AuthBackendContract auth = MockAuthBackend();

  @override
  final TenantBackendContract tenant = MockTenantBackend();

  @override
  final PartnersBackendContract partners = MockPartnersBackend();

  @override
  final FavoriteBackendContract favorites = MockFavoriteBackend();

  @override
  final VenueEventBackendContract venueEvents = MockVenueEventBackend();

  @override
  final ScheduleBackendContract schedule = MockScheduleBackend();
}

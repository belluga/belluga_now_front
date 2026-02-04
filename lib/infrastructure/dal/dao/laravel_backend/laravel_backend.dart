import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/partners_backend/laravel_account_profiles_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/schedule_backend/laravel_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_auth_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_favorite_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_tenant_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_venue_event_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';

class LaravelBackend extends BackendContract {
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
  final AccountProfilesBackendContract accountProfiles =
      LaravelAccountProfilesBackend();

  @override
  final FavoriteBackendContract favorites = MockFavoriteBackend();

  @override
  final VenueEventBackendContract venueEvents = MockVenueEventBackend();

  @override
  final ScheduleBackendContract schedule = LaravelScheduleBackend();
}

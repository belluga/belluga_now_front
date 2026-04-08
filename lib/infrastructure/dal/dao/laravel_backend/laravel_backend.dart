import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/auth_backend/auth_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/favorite_backend/laravel_favorite_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/partners_backend/laravel_account_profiles_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/static_assets_backend/laravel_static_assets_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/schedule_backend/laravel_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/static_assets_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/live_only_unsupported_backends.dart';
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
  final AuthBackendContract auth = LaravelAuthBackend();

  @override
  final TenantBackendContract tenant = const LiveOnlyUnsupportedTenantBackend();

  @override
  final AccountProfilesBackendContract accountProfiles =
      LaravelAccountProfilesBackend();

  @override
  final StaticAssetsBackendContract staticAssets = LaravelStaticAssetsBackend();

  @override
  final FavoriteBackendContract favorites = LaravelFavoriteBackend();

  @override
  final VenueEventBackendContract venueEvents =
      const LiveOnlyUnsupportedVenueEventBackend();

  @override
  final ScheduleBackendContract schedule = LaravelScheduleBackend();
}

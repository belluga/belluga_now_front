import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/auth_backend/auth_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/favorite_backend/laravel_favorite_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/partners_backend/laravel_account_profiles_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/schedule_backend/laravel_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/live_only_unsupported_backends.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';

class ProductionBackend extends BackendContract {
  ProductionBackend({
    AppDataBackendContract? appData,
    AuthBackendContract? auth,
    TenantBackendContract? tenant,
    AccountProfilesBackendContract? accountProfiles,
    FavoriteBackendContract? favorites,
    VenueEventBackendContract? venueEvents,
    ScheduleBackendContract? schedule,
  })  : _appData = appData ?? AppDataBackend(),
        _auth = auth ?? LaravelAuthBackend(),
        _tenant = tenant ?? const LiveOnlyUnsupportedTenantBackend(),
        _accountProfiles = accountProfiles ?? LaravelAccountProfilesBackend(),
        _favorites = favorites ?? LaravelFavoriteBackend(),
        _venueEvents =
            venueEvents ?? const LiveOnlyUnsupportedVenueEventBackend(),
        _schedule = schedule ?? LaravelScheduleBackend();

  BackendContext? _context;
  final AppDataBackendContract _appData;
  final AuthBackendContract _auth;
  final TenantBackendContract _tenant;
  final AccountProfilesBackendContract _accountProfiles;
  final FavoriteBackendContract _favorites;
  final VenueEventBackendContract _venueEvents;
  final ScheduleBackendContract _schedule;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  AppDataBackendContract get appData => _appData;

  @override
  AuthBackendContract get auth => _auth;

  @override
  TenantBackendContract get tenant => _tenant;

  @override
  AccountProfilesBackendContract get accountProfiles => _accountProfiles;

  @override
  FavoriteBackendContract get favorites => _favorites;

  @override
  VenueEventBackendContract get venueEvents => _venueEvents;

  @override
  ScheduleBackendContract get schedule => _schedule;
}

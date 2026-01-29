import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_routing_policy.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/auth_backend/auth_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/partners_backend/laravel_partners_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/schedule_backend/laravel_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_favorite_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_partners_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_schedule_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_tenant_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/mock_backend/mock_venue_event_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/partners_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';

class ProductionBackend extends BackendContract {
  ProductionBackend({
    BackendRoutingPolicy? routingPolicy,
    AppDataBackendContract? appDataLive,
    AppDataBackendContract? appDataMock,
    TenantBackendContract? tenantLive,
    TenantBackendContract? tenantMock,
    PartnersBackendContract? partnersLive,
    PartnersBackendContract? partnersMock,
    ScheduleBackendContract? scheduleLive,
    ScheduleBackendContract? scheduleMock,
  })  : _routingPolicy =
            routingPolicy ?? BellugaConstants.backendRoutingPolicy,
        _appDataLive = appDataLive ?? AppDataBackend(),
        _appDataMock = appDataMock ?? AppDataBackend(),
        _tenantLive = tenantLive ?? MockTenantBackend(),
        _tenantMock = tenantMock ?? MockTenantBackend(),
        _partnersLive = partnersLive ?? LaravelPartnersBackend(),
        _partnersMock = partnersMock ?? MockPartnersBackend(),
        _scheduleLive = scheduleLive ?? LaravelScheduleBackend(),
        _scheduleMock = scheduleMock ?? MockScheduleBackend();

  final BackendRoutingPolicy _routingPolicy;
  BackendContext? _context;
  final AppDataBackendContract _appDataLive;
  final AppDataBackendContract _appDataMock;
  final TenantBackendContract _tenantLive;
  final TenantBackendContract _tenantMock;
  final PartnersBackendContract _partnersLive;
  final PartnersBackendContract _partnersMock;
  final ScheduleBackendContract _scheduleLive;
  final ScheduleBackendContract _scheduleMock;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  AppDataBackendContract get appData =>
      _routingPolicy.resolve(BackendDomain.appData) == BackendSource.mock
          ? _appDataMock
          : _appDataLive;

  @override
  final AuthBackendContract auth = LaravelAuthBackend();

  @override
  // TODO(Delphi): Replace with a Laravel tenant backend once the adapter exists.
  // Next: implement `TenantBackendContract` backed by `/api/v1/tenant` and wire it here.
  TenantBackendContract get tenant =>
      _routingPolicy.resolve(BackendDomain.tenant) == BackendSource.mock
          ? _tenantMock
          : _tenantLive;

  @override
  PartnersBackendContract get partners =>
      _routingPolicy.resolve(BackendDomain.partners) == BackendSource.mock
          ? _partnersMock
          : _partnersLive;

  @override
  // TODO(Delphi): Replace with a Laravel favorites backend once the adapter exists.
  // Next: implement `FavoriteBackendContract` backed by favorites endpoints and wire it here.
  final FavoriteBackendContract favorites = MockFavoriteBackend();

  @override
  // TODO(Delphi): Replace with a Laravel venue events backend once the adapter exists.
  // Next: implement `VenueEventBackendContract` backed by `/api/v1/venue-events` and wire it here.
  final VenueEventBackendContract venueEvents = MockVenueEventBackend();

  @override
  ScheduleBackendContract get schedule =>
      _routingPolicy.resolve(BackendDomain.schedule) == BackendSource.mock
          ? _scheduleMock
          : _scheduleLive;
}

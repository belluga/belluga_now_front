import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';

abstract class BackendContract {
  AuthBackendContract get auth;
  TenantBackendContract get tenant;
  FavoriteBackendContract get favorites;
  VenueEventBackendContract get venueEvents;
  ScheduleBackendContract get schedule;
}

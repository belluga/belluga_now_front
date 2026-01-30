import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';

abstract class BackendContract {
  BackendContext? get context;
  void setContext(BackendContext context);

  AppDataBackendContract get appData;
  AuthBackendContract get auth;
  TenantBackendContract get tenant;
  AccountProfilesBackendContract get accountProfiles;
  FavoriteBackendContract get favorites;
  VenueEventBackendContract get venueEvents;
  ScheduleBackendContract get schedule;
}

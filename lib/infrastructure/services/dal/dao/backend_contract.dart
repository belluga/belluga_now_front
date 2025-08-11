import 'package:belluga_now/infrastructure/services/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/tenant_backend_contract.dart';

abstract class BackendContract {

  AuthBackendContract get auth;
  TenantBackendContract get tenant;
}

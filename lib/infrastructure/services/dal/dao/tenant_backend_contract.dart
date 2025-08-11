import 'package:belluga_now/domain/tenant/tenant.dart';

abstract class TenantBackendContract {

  Future<Tenant> getTenant();

}

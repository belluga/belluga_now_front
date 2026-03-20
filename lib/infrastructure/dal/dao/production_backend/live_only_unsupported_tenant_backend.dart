import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';

class LiveOnlyUnsupportedTenantBackend implements TenantBackendContract {
  const LiveOnlyUnsupportedTenantBackend();

  @override
  Future<Tenant> getTenant() {
    throw UnsupportedError(
      'Tenant backend adapter is not available in runtime. '
      'Tenant resolution must come from app bootstrap data.',
    );
  }
}

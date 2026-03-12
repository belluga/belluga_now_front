export 'landlord_tenant_option.dart';

import 'package:belluga_now/domain/repositories/landlord_tenant_option.dart';

abstract class LandlordTenantsRepositoryContract {
  Future<List<LandlordTenantOption>> fetchTenants();
}

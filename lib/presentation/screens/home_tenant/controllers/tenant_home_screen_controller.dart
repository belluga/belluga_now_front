import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:get_it/get_it.dart';

class TenantHomeScreenController {
  final tenantRepository = GetIt.I.get<TenantRepositoryContract>();
  
  Tenant get tenant => tenantRepository.tenant!;

  TenantHomeScreenController();

  Future<void> init() async {
    await tenantRepository.init();
  }
}

import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminSelectedTenantRepositoryContract {
  StreamValue<List<LandlordTenantOption>> get availableTenantsStreamValue;

  List<LandlordTenantOption> get availableTenants;

  StreamValue<String?> get selectedTenantDomainStreamValue;

  String? get selectedTenantDomain;

  StreamValue<LandlordTenantOption?> get selectedTenantStreamValue;

  LandlordTenantOption? get selectedTenant;

  String get selectedTenantAdminBaseUrl;

  void setAvailableTenants(List<LandlordTenantOption> tenants);

  void selectTenantDomain(String tenantDomain);

  void selectTenant(LandlordTenantOption tenant);

  void clearSelectedTenant();
}

import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_lookup_domain_value.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminSelectedTenantRepositoryContractPrimString = String;
typedef TenantAdminSelectedTenantRepositoryContractPrimInt = int;
typedef TenantAdminSelectedTenantRepositoryContractPrimBool = bool;
typedef TenantAdminSelectedTenantRepositoryContractPrimDouble = double;
typedef TenantAdminSelectedTenantRepositoryContractPrimDateTime = DateTime;
typedef TenantAdminSelectedTenantRepositoryContractPrimDynamic = dynamic;

abstract class TenantAdminSelectedTenantRepositoryContract {
  StreamValue<List<LandlordTenantOption>> get availableTenantsStreamValue;

  List<LandlordTenantOption> get availableTenants;

  StreamValue<TenantAdminSelectedTenantRepositoryContractPrimString?>
      get selectedTenantDomainStreamValue;

  TenantAdminSelectedTenantRepositoryContractPrimString?
      get selectedTenantDomain;

  StreamValue<LandlordTenantOption?> get selectedTenantStreamValue;

  LandlordTenantOption? get selectedTenant;

  TenantAdminSelectedTenantRepositoryContractPrimString
      get selectedTenantAdminBaseUrl;

  void setAvailableTenants(List<LandlordTenantOption> tenants);

  void selectTenantDomain(TenantLookupDomainValue tenantDomain);

  void selectTenant(LandlordTenantOption tenant);

  void clearSelectedTenant();
}

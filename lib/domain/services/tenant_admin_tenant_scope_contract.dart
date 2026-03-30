import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_lookup_domain_value.dart';

typedef TenantAdminTenantScopeContractPrimString = String;
typedef TenantAdminTenantScopeContractPrimInt = int;
typedef TenantAdminTenantScopeContractPrimBool = bool;
typedef TenantAdminTenantScopeContractPrimDouble = double;
typedef TenantAdminTenantScopeContractPrimDateTime = DateTime;
typedef TenantAdminTenantScopeContractPrimDynamic = dynamic;

abstract class TenantAdminTenantScopeContract {
  StreamValue<TenantAdminTenantScopeContractPrimString?>
      get selectedTenantDomainStreamValue;

  TenantAdminTenantScopeContractPrimString? get selectedTenantDomain;
  TenantAdminTenantScopeContractPrimString get selectedTenantAdminBaseUrl;

  void selectTenantDomain(TenantLookupDomainValue tenantDomain);
  void clearSelectedTenantDomain();
}

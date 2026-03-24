import 'package:stream_value/core/stream_value.dart';

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

  void selectTenantDomain(
      TenantAdminTenantScopeContractPrimString tenantDomain);
  void clearSelectedTenantDomain();
}

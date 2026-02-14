import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminTenantScopeContract {
  StreamValue<String?> get selectedTenantDomainStreamValue;

  String? get selectedTenantDomain;
  String get selectedTenantAdminBaseUrl;

  void selectTenantDomain(String tenantDomain);
  void clearSelectedTenantDomain();
}

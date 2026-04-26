import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_rule_catalog.dart';

abstract class TenantAdminDiscoveryFilterRuleCatalogRepositoryContract {
  Future<TenantAdminMapFilterRuleCatalog> fetchRuleCatalog();
}

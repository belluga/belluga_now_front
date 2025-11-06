import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/tenant/value_objects/app_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/subdomain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_name_value.dart';
import 'package:belluga_now/infrastructure/services/dal/dao/tenant_backend_contract.dart';

class MockTenantBackend extends TenantBackendContract {
  @override
  Future<Tenant> getTenant() async {
    return Tenant(
        name: TenantNameValue()..parse("Guarappari"),
        mainLogoUrl: MainLogoUrlValue()
          ..parse(
              "https://logodownload.org/wp-content/uploads/2018/08/aurora-logo-0.png"),
        subdomain: SubdomainValue()..parse("guarappari"),
        domains: [
          DomainValue()..parse("https://guarappari.com.br"),
        ],
        appDomains: [
          AppDomainValue()..parse("com.guarappari.app"),
        ]);
  }
}

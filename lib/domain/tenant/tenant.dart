import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/tenant/value_objects/app_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/subdomain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_name_value.dart';
import 'package:get_it/get_it.dart';

typedef TenantPrimString = String;
typedef TenantPrimInt = int;
typedef TenantPrimBool = bool;
typedef TenantPrimDouble = double;
typedef TenantPrimDateTime = DateTime;
typedef TenantPrimDynamic = dynamic;

class Tenant {
  final TenantNameValue name;
  final SubdomainValue subdomain;
  final MainLogoUrlValue mainLogoUrl;
  final IconUrlValue? iconUrl;
  final MainColorValue? mainColor;
  final List<DomainValue>? domains;
  final List<AppDomainValue>? appDomains;

  Tenant({
    required this.name,
    required this.subdomain,
    required this.mainLogoUrl,
    this.iconUrl,
    this.mainColor,
    this.domains,
    this.appDomains,
  });

  AppData get appData => GetIt.I.get<AppData>();

  TenantPrimString get landlordUrl => BellugaConstants.landlordDomain;

  TenantPrimString get subdomainFull => "${subdomain.value}.$landlordUrl";

  TenantPrimBool hasDomain(TenantPrimString domainTry) {
    switch (appData.appType) {
      case AppType.web:
        return hasWebDomain(domainTry);
      case AppType.mobile:
      case AppType.desktop:
        return hasAppDomain(domainTry);
    }
  }

  TenantPrimBool hasAppDomain(TenantPrimString domainTry) {
    return appDomains?.any((appDomain) {
          return appDomain.value == domainTry;
        }) ??
        false;
  }

  TenantPrimBool hasWebDomain(TenantPrimString domainTry) {
    final List<TenantPrimString> _splitted = domainTry.split(".$landlordUrl");

    if (_splitted.length == 1) {
      return domains?.any((domain) {
            return domain.value!.host == _splitted.first;
          }) ??
          false;
    }

    if (_splitted.length > 1) {
      return subdomainFull == domainTry;
    }

    return true;
  }
}

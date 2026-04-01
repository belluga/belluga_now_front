import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/tenant/value_objects/app_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_domain_match_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_lookup_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/subdomain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_name_value.dart';
import 'package:get_it/get_it.dart';

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

  TenantLookupDomainValue get landlordUrlValue {
    final value = TenantLookupDomainValue();
    value.parse(BellugaConstants.landlordDomain);
    return value;
  }

  TenantLookupDomainValue get subdomainFullValue {
    final value = TenantLookupDomainValue();
    value.parse('${subdomain.value}.${landlordUrlValue.value}');
    return value;
  }

  TenantDomainMatchValue hasDomain(TenantLookupDomainValue domainTryValue) {
    switch (appData.appType) {
      case AppType.web:
        return hasWebDomain(domainTryValue);
      case AppType.mobile:
      case AppType.desktop:
        return hasAppDomain(domainTryValue);
    }
  }

  TenantDomainMatchValue hasAppDomain(TenantLookupDomainValue domainTryValue) {
    final normalizedTry = domainTryValue.value;
    final hasMatch = appDomains?.any((appDomain) {
          return appDomain.value.toLowerCase() == normalizedTry;
        }) ??
        false;
    final value = TenantDomainMatchValue();
    value.parse(hasMatch.toString());
    return value;
  }

  TenantDomainMatchValue hasWebDomain(TenantLookupDomainValue domainTryValue) {
    final domainTry = domainTryValue.value;
    final landlordUrl = landlordUrlValue.value;
    final subdomainFull = subdomainFullValue.value;
    final splitDomain = domainTry.split('.$landlordUrl');

    if (splitDomain.length == 1) {
      final hasMatch = domains?.any((domain) {
            return domain.value!.host.toLowerCase() == splitDomain.first;
          }) ??
          false;
      final value = TenantDomainMatchValue();
      value.parse(hasMatch.toString());
      return value;
    }

    if (splitDomain.length > 1) {
      final value = TenantDomainMatchValue();
      value.parse((subdomainFull == domainTry).toString());
      return value;
    }

    final fallback = TenantDomainMatchValue();
    fallback.parse('true');
    return fallback;
  }
}

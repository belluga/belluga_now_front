import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/infrastructure/tenant/dtos/tenant_dto.dart';
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

  factory Tenant.fromDto(TenantDto dto) {
    return Tenant(
      name: TenantNameValue()..parse(dto.name),
      subdomain: SubdomainValue()..parse(dto.subdomain),
      mainLogoUrl: MainLogoUrlValue()..parse(dto.mainLogoUrl),
      iconUrl:
          dto.iconUrl != null ? (IconUrlValue()..parse(dto.iconUrl!)) : null,
      mainColor: dto.mainColor != null
          ? (MainColorValue()..parse(dto.mainColor!))
          : null,
      domains: dto.domains?.map((d) => DomainValue()..parse(d)).toList(),
      appDomains:
          dto.appDomains?.map((d) => AppDomainValue()..parse(d)).toList(),
    );
  }

  AppData get appData => GetIt.I.get<AppData>();

  String get landlordUrl => BellugaConstants.landlordDomain;

  String get subdomainFull => "${subdomain.value}.$landlordUrl";

  bool hasDomain(String domainTry) {
    switch (appData.appType) {
      case AppType.web:
        return hasWebDomain(domainTry);
      case AppType.mobile:
      case AppType.desktop:
        return hasAppDomain(domainTry);
    }
  }

  bool hasAppDomain(String domainTry) {
    return appDomains?.any((appDomain) {
          return appDomain.value == domainTry;
        }) ??
        false;
  }

  bool hasWebDomain(String domainTry) {
    final List<String> _splitted = domainTry.split(".$landlordUrl");

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

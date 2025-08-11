import 'package:belluga_now/domain/tenant/value_objects/domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/subdomain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_name_value.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Tenant {
  final TenantNameValue name;
  final SubdomainValue subdomain;
  final MainLogoUrlValue mainLogoUrl;
  final List<DomainValue>? domains;

  Tenant({
    required this.name,
    required this.subdomain,
    required this.mainLogoUrl,
    this.domains,
  });

  String get landlordUrl => dotenv.env['LANDLORD_DOMAIN']!;

  String get subdomainFull =>
      "${subdomain.value}.$landlordUrl";

  bool hasDomain(String domainTry) {
    final List<String> _splitted = domainTry.split(".$landlordUrl");

    if (_splitted.length == 1) {
      return domains
              ?.any((domain) {
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

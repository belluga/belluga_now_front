import 'package:belluga_now/domain/repositories/landlord_tenant_option.dart';
import 'package:belluga_now/domain/tenant/value_objects/app_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_name_value.dart';

TenantIdValue landlordTenantOptionId(Object? raw) {
  if (raw is TenantIdValue) {
    return raw;
  }

  final value = TenantIdValue();
  value.parse(raw?.toString());
  return value;
}

TenantNameValue landlordTenantOptionName(Object? raw) {
  if (raw is TenantNameValue) {
    return raw;
  }

  final value = TenantNameValue();
  value.parse(raw?.toString());
  return value;
}

AppDomainValue landlordTenantOptionMainDomain(Object? raw) {
  if (raw is AppDomainValue) {
    return raw;
  }

  final value = AppDomainValue();
  value.parse(raw?.toString());
  return value;
}

LandlordTenantOption landlordTenantOptionFromRaw({
  required Object? id,
  required Object? name,
  required Object? mainDomain,
}) {
  return LandlordTenantOption(
    idValue: landlordTenantOptionId(id),
    nameValue: landlordTenantOptionName(name),
    mainDomainValue: landlordTenantOptionMainDomain(mainDomain),
  );
}

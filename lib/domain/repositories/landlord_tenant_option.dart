import 'package:belluga_now/domain/tenant/value_objects/app_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_id_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_name_value.dart';

typedef LandlordTenantOptionPrimString = String;
typedef LandlordTenantOptionPrimInt = int;
typedef LandlordTenantOptionPrimBool = bool;
typedef LandlordTenantOptionPrimDouble = double;
typedef LandlordTenantOptionPrimDateTime = DateTime;
typedef LandlordTenantOptionPrimDynamic = dynamic;

class LandlordTenantOption {
  LandlordTenantOption({
    required this.idValue,
    required this.nameValue,
    required this.mainDomainValue,
  });

  final TenantIdValue idValue;
  final TenantNameValue nameValue;
  final AppDomainValue mainDomainValue;

  LandlordTenantOptionPrimString get id => idValue.value;
  LandlordTenantOptionPrimString get name => nameValue.value;
  LandlordTenantOptionPrimString get mainDomain => mainDomainValue.value;
}

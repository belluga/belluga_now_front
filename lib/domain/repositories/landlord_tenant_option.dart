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
    required Object id,
    required Object name,
    required Object mainDomain,
  })  : idValue = _parseId(id),
        nameValue = _parseName(name),
        mainDomainValue = _parseMainDomain(mainDomain);

  final TenantIdValue idValue;
  final TenantNameValue nameValue;
  final AppDomainValue mainDomainValue;

  LandlordTenantOptionPrimString get id => idValue.value;
  LandlordTenantOptionPrimString get name => nameValue.value;
  LandlordTenantOptionPrimString get mainDomain => mainDomainValue.value;

  @override
  LandlordTenantOptionPrimBool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandlordTenantOption &&
        other.idValue == idValue &&
        other.nameValue == nameValue &&
        other.mainDomainValue == mainDomainValue;
  }

  @override
  LandlordTenantOptionPrimInt get hashCode =>
      Object.hash(idValue, nameValue, mainDomainValue);

  static TenantIdValue _parseId(Object raw) {
    if (raw is TenantIdValue) {
      return raw;
    }
    final value = TenantIdValue();
    value.parse(raw.toString());
    return value;
  }

  static TenantNameValue _parseName(Object raw) {
    if (raw is TenantNameValue) {
      return raw;
    }
    final value = TenantNameValue();
    value.parse(raw.toString());
    return value;
  }

  static AppDomainValue _parseMainDomain(Object raw) {
    if (raw is AppDomainValue) {
      return raw;
    }
    final value = AppDomainValue();
    value.parse(raw.toString());
    return value;
  }
}

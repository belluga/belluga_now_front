typedef LandlordTenantOptionPrimString = String;
typedef LandlordTenantOptionPrimInt = int;
typedef LandlordTenantOptionPrimBool = bool;
typedef LandlordTenantOptionPrimDouble = double;
typedef LandlordTenantOptionPrimDateTime = DateTime;
typedef LandlordTenantOptionPrimDynamic = dynamic;

class LandlordTenantOption {
  const LandlordTenantOption({
    required this.id,
    required this.name,
    required this.mainDomain,
  });

  final LandlordTenantOptionPrimString id;
  final LandlordTenantOptionPrimString name;
  final LandlordTenantOptionPrimString mainDomain;

  @override
  LandlordTenantOptionPrimBool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandlordTenantOption &&
        other.id == id &&
        other.name == name &&
        other.mainDomain == mainDomain;
  }

  @override
  LandlordTenantOptionPrimInt get hashCode => Object.hash(id, name, mainDomain);
}

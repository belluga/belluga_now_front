class LandlordTenantOption {
  const LandlordTenantOption({
    required this.id,
    required this.name,
    required this.mainDomain,
  });

  final String id;
  final String name;
  final String mainDomain;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LandlordTenantOption &&
        other.id == id &&
        other.name == name &&
        other.mainDomain == mainDomain;
  }

  @override
  int get hashCode => Object.hash(id, name, mainDomain);
}

abstract class LandlordTenantsRepositoryContract {
  Future<List<LandlordTenantOption>> fetchTenants();
}

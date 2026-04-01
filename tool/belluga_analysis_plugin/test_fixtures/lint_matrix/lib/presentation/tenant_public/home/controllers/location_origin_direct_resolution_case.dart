class CityCoordinate {
  const CityCoordinate();
}

class AppData {
  CityCoordinate? get tenantDefaultOrigin => const CityCoordinate();
}

enum LocationOriginReason {
  outsideRange,
}

class LocationOriginSettings {
  LocationOriginSettings.tenantDefaultLocation({
    required CityCoordinate fixedLocationReference,
    required LocationOriginReason reason,
  });
}

class LocationOriginDirectResolutionCase {
  LocationOriginDirectResolutionCase(this.appData);

  final AppData appData;

  CityCoordinate? resolveOrigin() {
    // expect_lint: location_origin_canonical_resolution_required
    final tenantDefaultOrigin = appData.tenantDefaultOrigin;
    if (tenantDefaultOrigin == null) {
      return null;
    }

    // expect_lint: location_origin_canonical_resolution_required
    LocationOriginSettings.tenantDefaultLocation(
      fixedLocationReference: tenantDefaultOrigin,
      // expect_lint: location_origin_canonical_resolution_required
      reason: LocationOriginReason.outsideRange,
    );
    return tenantDefaultOrigin;
  }
}

import 'package:belluga_now/domain/app_data/location_origin_resolution_request.dart';
import 'package:belluga_now/domain/app_data/location_origin_resolution.dart';

abstract class LocationOriginServiceContract {
  LocationOriginResolution resolveCached();

  Future<LocationOriginResolution> resolve(
    LocationOriginResolutionRequest request,
  );

  Future<LocationOriginResolution> resolveAndPersist(
    LocationOriginResolutionRequest request,
  );
}

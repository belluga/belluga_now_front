import 'package:belluga_now/domain/app_data/location_origin_resolution_request.dart';
import 'package:belluga_now/domain/app_data/location_origin_resolution.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class LocationOriginServiceContract {
  StreamValue<LocationOriginResolution?> get effectiveOriginStreamValue;

  LocationOriginResolution resolveCached();

  Future<LocationOriginResolution> resolve(
    LocationOriginResolutionRequest request,
  );

  Future<LocationOriginResolution> resolveAndPersist(
    LocationOriginResolutionRequest request,
  );
}

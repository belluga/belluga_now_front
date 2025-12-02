import 'package:belluga_now/domain/map/ride_share_option.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:map_launcher/map_launcher.dart';

class DirectionsInfo {
  const DirectionsInfo({
    required this.coordinate,
    required this.destination,
    required this.destinationName,
    required this.availableMaps,
    required this.rideShareOptions,
    required this.fallbackUrl,
  });

  final CityCoordinate coordinate;
  final Coords destination;
  final String destinationName;
  final List<AvailableMap> availableMaps;
  final List<RideShareOption> rideShareOptions;
  final Uri fallbackUrl;
}

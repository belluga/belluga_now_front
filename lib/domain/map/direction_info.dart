import 'package:belluga_now/domain/map/ride_share_option.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/directions_destination_name_value.dart';
import 'package:belluga_now/domain/map/value_objects/directions_fallback_url_value.dart';
import 'package:map_launcher/map_launcher.dart';

class DirectionsInfo {
  const DirectionsInfo({
    required this.coordinate,
    required this.destination,
    required this.destinationNameValue,
    required this.availableMaps,
    required this.rideShareOptions,
    required this.fallbackUrlValue,
  });

  final CityCoordinate coordinate;
  final Coords destination;
  final DirectionsDestinationNameValue destinationNameValue;
  final List<AvailableMap> availableMaps;
  final List<RideShareOption> rideShareOptions;
  final DirectionsFallbackUrlValue fallbackUrlValue;

  String get destinationName => destinationNameValue.value;

  Uri get fallbackUrl => fallbackUrlValue.value;
}

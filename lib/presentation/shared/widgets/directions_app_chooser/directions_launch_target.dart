class DirectionsLaunchTarget {
  const DirectionsLaunchTarget({
    required this.destinationName,
    this.latitude,
    this.longitude,
    this.address,
    this.originName,
    this.originLatitude,
    this.originLongitude,
    this.originAddress,
  });

  final String destinationName;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? originName;
  final double? originLatitude;
  final double? originLongitude;
  final String? originAddress;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasAddress => (address?.trim() ?? '').isNotEmpty;

  bool get hasLaunchableDestination => hasCoordinates || hasAddress;

  String get trimmedAddress => address?.trim() ?? '';

  bool get hasOriginCoordinates =>
      originLatitude != null && originLongitude != null;

  bool get hasOriginAddress => (originAddress?.trim() ?? '').isNotEmpty;

  bool get hasLaunchableOrigin => hasOriginCoordinates || hasOriginAddress;

  String get trimmedOriginAddress => originAddress?.trim() ?? '';

  String get originDisplayName {
    final value = originName?.trim();
    return value == null || value.isEmpty ? 'Ponto de referência' : value;
  }
}

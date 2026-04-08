class DirectionsLaunchTarget {
  const DirectionsLaunchTarget({
    required this.destinationName,
    this.latitude,
    this.longitude,
    this.address,
  });

  final String destinationName;
  final double? latitude;
  final double? longitude;
  final String? address;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasAddress => (address?.trim() ?? '').isNotEmpty;

  bool get hasLaunchableDestination => hasCoordinates || hasAddress;

  String get trimmedAddress => address?.trim() ?? '';
}

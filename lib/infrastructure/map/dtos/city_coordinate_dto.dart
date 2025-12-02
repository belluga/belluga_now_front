class CityCoordinateDto {
  final double latitude;
  final double longitude;

  CityCoordinateDto({
    required this.latitude,
    required this.longitude,
  });

  factory CityCoordinateDto.fromJson(Map<String, dynamic> json) {
    return CityCoordinateDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

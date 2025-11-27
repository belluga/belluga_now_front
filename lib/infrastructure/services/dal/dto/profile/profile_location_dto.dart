class ProfileLocationDTO {
  ProfileLocationDTO({
    required this.address,
    required this.status,
    this.lat,
    this.lng,
  });

  final String address;
  final String status;
  final String? lat;
  final String? lng;
}

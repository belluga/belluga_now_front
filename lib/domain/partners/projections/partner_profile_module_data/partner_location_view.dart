part of '../partner_profile_module_data.dart';

class PartnerLocationView {
  const PartnerLocationView({
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

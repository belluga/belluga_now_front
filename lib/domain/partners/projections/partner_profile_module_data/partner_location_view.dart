part of '../partner_profile_module_data.dart';

typedef PartnerLocationAddress = String;
typedef PartnerLocationStatus = String;
typedef PartnerLocationLatitude = String;
typedef PartnerLocationLongitude = String;

class PartnerLocationView {
  const PartnerLocationView({
    required this.address,
    required this.status,
    this.lat,
    this.lng,
  });

  final PartnerLocationAddress address;
  final PartnerLocationStatus status;
  final PartnerLocationLatitude? lat;
  final PartnerLocationLongitude? lng;
}

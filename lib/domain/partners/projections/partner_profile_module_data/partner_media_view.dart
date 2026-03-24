part of '../partner_profile_module_data.dart';

typedef PartnerMediaUrl = String;
typedef PartnerMediaTitle = String;

class PartnerMediaView {
  const PartnerMediaView({
    required this.url,
    this.title,
  });

  final PartnerMediaUrl url;
  final PartnerMediaTitle? title;
}

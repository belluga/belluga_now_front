part of '../partner_profile_module_data.dart';

typedef PartnerExperienceTitle = String;
typedef PartnerExperienceDuration = String;
typedef PartnerExperiencePrice = String;

class PartnerExperienceView {
  const PartnerExperienceView({
    required this.title,
    required this.duration,
    required this.price,
  });

  final PartnerExperienceTitle title;
  final PartnerExperienceDuration duration;
  final PartnerExperiencePrice price;
}

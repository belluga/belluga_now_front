part of '../partner_profile_module_data.dart';

typedef PartnerRecommendationTitle = String;
typedef PartnerRecommendationType = String;

class PartnerRecommendationView {
  const PartnerRecommendationView({
    required this.title,
    required this.type,
  });

  final PartnerRecommendationTitle title;
  final PartnerRecommendationType type;
}

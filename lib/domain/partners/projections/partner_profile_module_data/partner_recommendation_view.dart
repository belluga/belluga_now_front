part of '../partner_profile_module_data.dart';

class PartnerRecommendationView {
  PartnerRecommendationView({
    required this.titleValue,
    required this.typeValue,
  });

  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionRequiredTextValue typeValue;

  String get title => titleValue.value;
  String get type => typeValue.value;
}

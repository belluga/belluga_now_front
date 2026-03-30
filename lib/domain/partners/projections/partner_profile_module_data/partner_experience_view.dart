part of '../partner_profile_module_data.dart';

class PartnerExperienceView {
  PartnerExperienceView({
    required this.titleValue,
    required this.durationValue,
    required this.priceValue,
  });

  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionRequiredTextValue durationValue;
  final PartnerProjectionRequiredTextValue priceValue;

  String get title => titleValue.value;
  String get duration => durationValue.value;
  String get price => priceValue.value;
}

part of '../partner_profile_module_data.dart';

class PartnerFaqView {
  PartnerFaqView({
    required this.questionValue,
    required this.answerValue,
  });

  final PartnerProjectionRequiredTextValue questionValue;
  final PartnerProjectionRequiredTextValue answerValue;

  String get question => questionValue.value;
  String get answer => answerValue.value;
}

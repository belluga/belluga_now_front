part of '../partner_profile_module_data.dart';

typedef PartnerFaqQuestion = String;
typedef PartnerFaqAnswer = String;

class PartnerFaqView {
  const PartnerFaqView({
    required this.question,
    required this.answer,
  });

  final PartnerFaqQuestion question;
  final PartnerFaqAnswer answer;
}

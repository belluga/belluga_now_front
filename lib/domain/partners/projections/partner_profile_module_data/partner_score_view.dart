part of '../partner_profile_module_data.dart';

class PartnerScoreView {
  PartnerScoreView({
    required this.invitesValue,
    required this.presencesValue,
  });

  final PartnerProjectionRequiredTextValue invitesValue;
  final PartnerProjectionRequiredTextValue presencesValue;

  String get invites => invitesValue.value;
  String get presences => presencesValue.value;
}

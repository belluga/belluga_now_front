part of '../partner_profile_module_data.dart';

typedef PartnerScoreInvites = String;
typedef PartnerScorePresences = String;

class PartnerScoreView {
  const PartnerScoreView({
    required this.invites,
    required this.presences,
  });

  final PartnerScoreInvites invites;
  final PartnerScorePresences presences;
}

part of '../partner_profile_module_data.dart';

typedef PartnerLinkTitle = String;
typedef PartnerLinkSubtitle = String;
typedef PartnerLinkIcon = String;

class PartnerLinkView {
  const PartnerLinkView({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final PartnerLinkTitle title;
  final PartnerLinkSubtitle subtitle;
  final PartnerLinkIcon icon;
}

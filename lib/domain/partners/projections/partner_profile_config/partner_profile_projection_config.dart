part of '../partner_profile_config.dart';

class PartnerProfileConfig {
  PartnerProfileConfig({
    required this.partner,
    required this.tabs,
  });

  final AccountProfileModel partner;
  final List<ProfileTabConfig> tabs;
}

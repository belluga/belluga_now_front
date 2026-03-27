part of '../partner_profile_config.dart';

class ProfileTabConfig {
  ProfileTabConfig({
    required this.titleValue,
    required this.modules,
  });

  final PartnerProjectionRequiredTextValue titleValue;
  final List<ProfileModuleConfig> modules;

  String get title => titleValue.value;
}

part of '../partner_profile_config.dart';

typedef ProfileTabTitle = String;

class ProfileTabConfig {
  ProfileTabConfig({
    required this.title,
    required this.modules,
  });

  final ProfileTabTitle title;
  final List<ProfileModuleConfig> modules;
}

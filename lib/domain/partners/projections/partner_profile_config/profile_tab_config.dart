part of '../partner_profile_config.dart';

class ProfileTabConfig {
  ProfileTabConfig({
    required this.title,
    required this.modules,
  });

  final String title;
  final List<ProfileModuleConfig> modules;
}

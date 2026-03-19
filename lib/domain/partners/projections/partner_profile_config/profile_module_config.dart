part of '../partner_profile_config.dart';

class ProfileModuleConfig {
  ProfileModuleConfig({
    required this.id,
    this.title,
    this.dataKey,
  });

  final ProfileModuleId id;
  final String? title;
  final String? dataKey;
}

part of '../partner_profile_config.dart';

typedef ProfileModuleTitle = String;
typedef ProfileModuleDataKey = String;

class ProfileModuleConfig {
  ProfileModuleConfig({
    required this.id,
    this.title,
    this.dataKey,
  });

  final ProfileModuleId id;
  final ProfileModuleTitle? title;
  final ProfileModuleDataKey? dataKey;
}

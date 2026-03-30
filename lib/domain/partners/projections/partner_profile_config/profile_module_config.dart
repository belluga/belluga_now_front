part of '../partner_profile_config.dart';

class ProfileModuleConfig {
  ProfileModuleConfig({
    required this.id,
    this.titleValue,
    this.dataKeyValue,
  });

  final ProfileModuleId id;
  final PartnerProjectionOptionalTextValue? titleValue;
  final PartnerProjectionOptionalTextValue? dataKeyValue;

  String? get title => titleValue?.value;
  String? get dataKey => dataKeyValue?.value;
}

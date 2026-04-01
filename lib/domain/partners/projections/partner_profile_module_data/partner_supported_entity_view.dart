part of '../partner_profile_module_data.dart';

class PartnerSupportedEntityView {
  PartnerSupportedEntityView({
    required this.titleValue,
    this.thumbValue,
  });

  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionOptionalTextValue? thumbValue;

  String get title => titleValue.value;
  String? get thumb => thumbValue?.value;
}

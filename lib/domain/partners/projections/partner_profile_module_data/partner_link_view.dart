part of '../partner_profile_module_data.dart';

class PartnerLinkView {
  PartnerLinkView({
    required this.titleValue,
    required this.subtitleValue,
    required this.iconValue,
  });

  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionRequiredTextValue subtitleValue;
  final PartnerProjectionRequiredTextValue iconValue;

  String get title => titleValue.value;
  String get subtitle => subtitleValue.value;
  String get icon => iconValue.value;
}

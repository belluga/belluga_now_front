part of '../partner_profile_module_data.dart';

class PartnerEventView {
  PartnerEventView({
    required this.titleValue,
    required this.dateValue,
    required this.locationValue,
  });

  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionRequiredTextValue dateValue;
  final PartnerProjectionRequiredTextValue locationValue;

  String get title => titleValue.value;
  String get date => dateValue.value;
  String get location => locationValue.value;
}

part of '../partner_profile_module_data.dart';

class PartnerLocationView {
  PartnerLocationView({
    required this.addressValue,
    required this.statusValue,
    this.latValue,
    this.lngValue,
  });

  final PartnerProjectionRequiredTextValue addressValue;
  final PartnerProjectionRequiredTextValue statusValue;
  final PartnerProjectionOptionalTextValue? latValue;
  final PartnerProjectionOptionalTextValue? lngValue;

  String get address => addressValue.value;
  String get status => statusValue.value;
  String? get lat => latValue?.value;
  String? get lng => lngValue?.value;
}

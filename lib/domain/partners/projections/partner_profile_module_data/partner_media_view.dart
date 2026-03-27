part of '../partner_profile_module_data.dart';

class PartnerMediaView {
  PartnerMediaView({
    required this.urlValue,
    this.titleValue,
  });

  final PartnerProjectionRequiredTextValue urlValue;
  final PartnerProjectionOptionalTextValue? titleValue;

  String get url => urlValue.value;
  String? get title => titleValue?.value;
}

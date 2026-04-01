part of '../partner_profile_module_data.dart';

class PartnerProductView {
  PartnerProductView({
    required this.titleValue,
    required this.priceValue,
    required this.imageUrlValue,
  });

  final PartnerProjectionRequiredTextValue titleValue;
  final PartnerProjectionRequiredTextValue priceValue;
  final PartnerProjectionRequiredTextValue imageUrlValue;

  String get title => titleValue.value;
  String get price => priceValue.value;
  String get imageUrl => imageUrlValue.value;
}

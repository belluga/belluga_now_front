part of '../partner_profile_module_data.dart';

typedef PartnerProductTitle = String;
typedef PartnerProductPrice = String;
typedef PartnerProductImageUrl = String;

class PartnerProductView {
  const PartnerProductView({
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  final PartnerProductTitle title;
  final PartnerProductPrice price;
  final PartnerProductImageUrl imageUrl;
}
